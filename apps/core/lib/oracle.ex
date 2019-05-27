defmodule Core.Oracle do
  @moduledoc """
  Module for oracle interaction, see: https://github.com/aeternity/protocol/blob/master/oracles/oracles.md
  """
  alias Utils.Transaction
  alias Utils.Account, as: AccountUtils
  alias Utils.{Keys, Hash, Encoding}
  alias Core.Client

  alias AeternityNode.Model.{
    RegisteredOracle,
    OracleRegisterTx,
    OracleQueryTx,
    OracleRespondTx,
    OracleExtendTx,
    Ttl,
    RelativeTtl,
    Error
  }

  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Api.Oracle, as: OracleApi

  @abi_version 0x01
  @nonce_size 256

  @typedoc """
  See https://github.com/aeternity/protocol/blob/master/contracts/sophia.md#types
  """
  @type sophia_type :: String.t()
  @type sophia_data :: any()
  @type ttl_type :: :relative | :absolute
  @type ttl :: %{type: ttl_type(), value: non_neg_integer()}

  @doc """
  Register a typed oracle. Queries and responses that don't follow the oracle's respective formats are invalid.
  The query and response types are sophia types.

  ## Examples
      iex> query_format = "string"
      iex> response_format = "map(string, string)"
      iex> oracle_ttl = %{type: :relative, value: 10}
      iex> query_fee = 100
      iex> Core.Oracle.register(client, query_format, response_format, oracle_ttl, query_fee)
      {:ok,
      %{
        block_hash: "mh_5zfVXCDwsBRjukTPjKRaS7T3TCc4Mn5PMTS19cWbcjRjeXjcF",
        block_height: 77276,
        oracle_id: "ok_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM",
        tx_hash: "th_21qrcDco5fL1cuaNqM1Ug1ojHiSzjnuEYzVEpwxVwuS2V95qBk"
      }}
  """
  @spec register(
          Client.t(),
          sophia_type(),
          sophia_type(),
          ttl(),
          non_neg_integer(),
          list()
        ) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c(),
             oracle_id: Encoding.base58c()
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def register(
        %Client{
          keypair: %{public: pubkey, secret: secret_key},
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        query_format,
        response_format,
        %{type: ttl_type, value: ttl_value} = ttl,
        query_fee,
        opts \\ []
      )
      when is_binary(query_format) and is_binary(response_format) and is_integer(query_fee) and
             query_fee > 0 and is_list(opts) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         {:ok, binary_query_format} <- sophia_type_to_binary(query_format),
         {:ok, binary_response_format} <- sophia_type_to_binary(response_format),
         register_tx = %OracleRegisterTx{
           query_format: binary_query_format,
           response_format: binary_response_format,
           query_fee: query_fee,
           oracle_ttl: %Ttl{type: ttl_type, value: ttl_value},
           account_id: pubkey,
           nonce: nonce,
           fee: Keyword.get(opts, :fee, 0),
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
           abi_version: @abi_version
         },
         {:ok, %{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         :ok <- validate_ttl(ttl, height),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             register_tx,
             height
           ) do
      {:ok, Map.put(response, :oracle_id, String.replace_prefix(pubkey, "ak", "ok"))}
    else
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Query an oracle. Keep in mind that the response TTL is always relative,
  and that the sum of the relative query and response TTL can't be higher than the oracle's TTL.

  ## Examples
      iex> oracle_id = "ok_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM"
      iex> query = "a query"
      iex> query_ttl = %{type: :relative, value: 10}
      iex> response_ttl = 10
      iex> Core.Oracle.query(client, oracle_id, query, query_ttl, response_ttl)
      {:ok,
       %{
         block_hash: "mh_2SgSB1yeekq8JseSfkKhAPuvs7RF3YUjm896g4aj2GPpSa9AnJ",
         block_height: 77276,
         query_id: "oq_u7sgmMQNjZQ4ffsN9sSmEhzqsag1iEfx8SkHDeG1y8EbDB5Aq",
         tx_hash: "th_2esUdavCBmW1oYSCichdQv3txyWXYsDSAum2jAvQfpgktJ4oEt"
       }}
  """
  @spec query(Client.t(), Encoding.base58c(), String.t(), ttl(), non_neg_integer(), list()) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c(),
             query_id: Encoding.base58c()
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def query(
        %Client{
          keypair: %{public: pubkey, secret: secret_key},
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        oracle_id,
        query,
        %{type: query_type, value: query_value} = query_ttl,
        response_ttl_value,
        opts \\ []
      )
      when is_binary(oracle_id) and is_integer(response_ttl_value) and is_list(opts) do
    with {:ok,
          %RegisteredOracle{
            query_fee: oracle_query_fee,
            ttl: oracle_ttl
          }} <- OracleApi.get_oracle_by_pubkey(connection, oracle_id),
         {:ok, binary_query} <- sophia_data_to_binary(query),
         {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         query_tx = %OracleQueryTx{
           oracle_id: oracle_id,
           query: binary_query,
           query_fee: Keyword.get(opts, :query_fee, oracle_query_fee),
           query_ttl: %Ttl{type: query_type, value: query_value},
           response_ttl: %RelativeTtl{type: :unused, value: response_ttl_value},
           fee: Keyword.get(opts, :fee, 0),
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
           sender_id: pubkey,
           nonce: nonce
         },
         {:ok, %{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         :ok <- validate_ttl(query_ttl, height),
         :ok <- validate_query_object_ttl(oracle_ttl, query_ttl, response_ttl_value, height),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             query_tx,
             height
           ) do
      {:ok, Map.put(response, :query_id, calculate_query_id(pubkey, nonce, oracle_id))}
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Respond to an oracle query. Only the oracle's owner can respond to its queries.

  ## Examples
      iex> oracle_id = "ok_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM"
      iex> query_id = "oq_u7sgmMQNjZQ4ffsN9sSmEhzqsag1iEfx8SkHDeG1y8EbDB5Aq"
      iex> response = %{"a" => "response"}
      iex> query_ttl = %{type: :relative, value: 10}
      iex> response_ttl = 10
      iex> Core.Oracle.respond(client, oracle_id, response, response_ttl)
      {:ok,
       %{
         block_hash: "mh_QTXMDn8Ln6fiBBXByXJkEeD6wq6QzQZHMVuApbouTFaqWMkSt",
         block_height: 77276,
         tx_hash: "th_2cBk9pBEwMSD3xtYMvrsFWJ3atuGN29XQUZfKV65KYMQuPJLiV"
       }}
  """
  @spec respond(
          Client.t(),
          Encoding.base58c(),
          Encoding.base58c(),
          sophia_data(),
          non_neg_integer(),
          list()
        ) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c()
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def respond(
        %Client{
          keypair: %{public: pubkey, secret: secret_key},
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        oracle_id,
        query_id,
        response,
        response_ttl,
        opts \\ []
      )
      when is_binary(oracle_id) and is_binary(query_id) and is_integer(response_ttl) and
             is_list(opts) do
    with {:ok, binary_response} <- sophia_data_to_binary(response),
         {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         response_tx = %OracleRespondTx{
           query_id: query_id,
           response: binary_response,
           response_ttl: %RelativeTtl{type: :relative, value: response_ttl},
           fee: Keyword.get(opts, :fee, 0),
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
           oracle_id: oracle_id,
           nonce: nonce
         },
         {:ok, %{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             response_tx,
             height
           ) do
      {:ok, response}
    else
      {:error, _} = err -> err
    end
  end

  @doc """
  Extend the TTL of an oracle by a relative amount.

  ## Examples
      iex> oracle_id = "ok_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM"
      iex> ttl = 10
      iex> Core.Oracle.extend(client, oracle_id, ttl)
      {:ok,
       %{
         block_hash: "mh_21HxnSLJRhqB9S3aUfLDAqR3BMFKPj62vT1zuy1MsS7N4Ps94s",
         block_height: 77276,
         tx_hash: "th_3911tboNbJWA6X57tejX8yGQALdeqAQECk1BwyS43pPtEXt4C"
       }}
  """
  @spec extend(Client.t(), Encoding.base58c(), non_neg_integer(), list()) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c()
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def extend(
        %Client{
          keypair: %{public: pubkey, secret: secret_key},
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        oracle_id,
        oracle_ttl,
        opts \\ []
      )
      when is_binary(oracle_id) and is_integer(oracle_ttl) and is_list(opts) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         extend_tx = %OracleExtendTx{
           fee: Keyword.get(opts, :fee, 0),
           oracle_ttl: %RelativeTtl{type: :relative, value: oracle_ttl},
           oracle_id: oracle_id,
           nonce: nonce,
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl())
         },
         {:ok, %{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             extend_tx,
             height
           ) do
      {:ok, response}
    else
      {:error, _} = err -> err
    end
  end

  @doc """
  Get an oracle object.

  ## Examples
      iex> oracle_id = "ok_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM"
      iex> Core.Oracle.get_oracle(client, oracle_id)
      {:ok,
       %{
         abi_version: 1,
         id: "ok_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM",
         query_fee: 30,
         query_format: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           239, 191, 189, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 239, 191, 189, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0>>,
         response_format: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 239, 191, 189, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 239, 191, 189, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0>>,
         ttl: 77316
       }}
  """
  @spec get_oracle(Client.t(), Encoding.base58c()) ::
          {:ok,
           %{
             id: Encoding.base58c(),
             query_format: binary(),
             response_format: binary(),
             query_fee: non_neg_integer(),
             ttl: non_neg_integer(),
             abi_version: non_neg_integer()
           }}
          | {:error, String.t()}
          | {:error, Env.t()}
  def get_oracle(
        %Client{
          connection: connection
        },
        oracle_id
      ) do
    case OracleApi.get_oracle_by_pubkey(connection, oracle_id) do
      {:ok,
       %RegisteredOracle{
         id: id,
         query_format: query_format,
         response_format: response_format,
         query_fee: query_fee,
         ttl: ttl,
         abi_version: abi_version
       }} ->
        {:ok,
         %{
           id: id,
           query_format: query_format,
           response_format: response_format,
           query_fee: query_fee,
           ttl: ttl,
           abi_version: abi_version
         }}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = err ->
        err
    end
  end

  defp calculate_query_id(sender, nonce, oracle_id) do
    binary_sender = Keys.public_key_to_binary(sender)
    binary_oracle_id = Keys.public_key_to_binary(oracle_id)

    {:ok, hash} =
      Hash.hash(<<binary_sender::binary, nonce::@nonce_size, binary_oracle_id::binary>>)

    Encoding.prefix_encode_base58c("oq", hash)
  end

  defp sophia_type_to_binary(type) do
    charlist_type = String.to_charlist(type)

    try do
      {:ok, typerep} = :aeso_compiler.sophia_type_to_typerep(charlist_type)
      {:ok, :aeb_heap.to_binary(typerep)}
    rescue
      _ -> {:error, "Bad Sophia type: #{type}"}
    end
  end

  defp sophia_data_to_binary(data) do
    try do
      {:ok, :aeb_heap.to_binary(data)}
    rescue
      _ -> {:error, "Bad Sophia data: #{data}"}
    end
  end

  defp validate_query_object_ttl(oracle_ttl, query_ttl, response_ttl, height) do
    relative_query_ttl =
      case query_ttl do
        %{type: :relative, value: value} ->
          value

        %{type: :absolute, value: value} ->
          value - height
      end

    if height + relative_query_ttl + response_ttl <= oracle_ttl do
      :ok
    else
      {:error, "Query objects can't outlive oracle - query and response TTL too high"}
    end
  end

  defp validate_ttl(%{type: type, value: value}, height) do
    ttl_valid =
      case type do
        :relative ->
          :ok

        :absolute ->
          if value > height do
            :ok
          else
            {:error, "Absolute TTL can't be lower than the current height"}
          end

        _ ->
          {:error, "Invalid TTL type: #{type}"}
      end

    with :ok <- ttl_valid,
         true <- is_integer(value) and value > 0 do
      :ok
    else
      {:error, _} = err ->
        err

      false ->
        {:error, "TTL value must be higher than 0"}
    end
  end
end
