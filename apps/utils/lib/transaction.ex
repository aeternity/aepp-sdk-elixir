defmodule Utils.Transaction do
  @moduledoc """
  Transaction utils
  """
  alias AeternityNode.Api.Transaction, as: TransactionApi

  alias AeternityNode.Model.{
    PostTxResponse,
    Tx,
    Error,
    GenericSignedTx,
    ContractCallObject,
    SpendTx,
    OracleRegisterTx,
    OracleQueryTx,
    OracleRespondTx,
    OracleExtendTx,
    NamePreclaimTx,
    NameClaimTx,
    NameTransferTx,
    NameRevokeTx,
    NameUpdateTx,
    ContractCallTx,
    ContractCreateTx
  }

  alias Utils.{Keys, Encoding, Serialization, Governance}
  alias Tesla.Env

  @struct_type [
    SpendTx,
    OracleRegisterTx,
    OracleQueryTx,
    OracleRespondTx,
    OracleExtendTx,
    NamePreclaimTx,
    NameClaimTx,
    NameTransferTx,
    NameRevokeTx,
    NameUpdateTx,
    ContractCallTx,
    ContractCreateTx
  ]

  @network_id_list ["ae_mainnet", "ae_uat"]

  @await_attempts 25
  @await_attempt_interval 200
  @default_ttl 0

  @doc """
  Serialize the list of fields to an RLP transaction binary, sign it with the private key and network ID and post it to the node

  ## Examples
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> secret_key = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> {:ok, nonce} = Utils.Account.next_valid_nonce(connection, public_key)
      iex> source_code = "contract Number =\n  record state = { number : int }\n\n  function init(x : int) =\n    { number = x }\n\n  function add_to_number(x : int) = state.number + x"
      iex> function_name = "init"
      iex> function_args = ["42"]
      iex> {:ok, calldata} = Core.Contract.create_calldata(source_code, function_name, function_args)
      iex> source_hash_bytes = 32
      iex> {:ok, source_hash} = :enacl.generichash(source_hash_bytes, source_code)
      iex> {:ok, %{byte_code: byte_code, type_info: type_info}} = Core.Contract.compile(source_code)
      iex> byte_code_fields = [
        source_hash,
        type_info,
        byte_code
      ]
      iex> serialized_wrapped_code = Utils.Serialization.serialize(byte_code_fields, :sophia_byte_code)
      iex> tx_dummy_fee = %AeternityNode.Model.ContractCreateTx{
        owner_id: public_key,
        nonce: nonce,
        code: serialized_wrapped_code,
        vm_version: :unused,
        abi_version: :unused,
        deposit: 0,
        amount: 0,
        gas: 1_000_000,
        gas_price: 1_000_000_000,
        fee: 0,
        ttl: Utils.Transaction.default_ttl(),
        call_data: calldata
      }
      iex> {:ok, %AeternityNode.Model.InlineResponse2001{height: height}} = AeternityNode.Api.Chain.get_current_key_block_height(connection)
      iex> tx = %{tx_dummy_fee | fee: Utils.Transaction.calculate_min_fee(tx_dummy_fee, height, network_id) * 100_000}
      iex> Utils.Transaction.post(connection, secret_key, network_id, tx)
      {:ok,
       %AeternityNode.Model.GenericSignedTx{
         block_hash: "mh_29ZNDHkaa1k54Gr9HqFDJ3ubDg7Wi6yJEsfuCy9qKQEjxeHdH4",
         block_height: 68240,
         hash: "th_gfVPUw5zerDAkokfanFrhoQk9WDJaCdbwS6dGxVQWZce7tU3j",
         signatures: ["sg_44yKiQRQ3NdDnAKiSJ7RDW9ku31GiiB5DmEXXNv4zYFYMzgkrujoLi2cmfHutXppucr7NaTpLkHBsjrXT54ekb4MGCKGX"],
         tx: %AeternityNode.Model.GenericTx{type: "ContractCreateTx", version: 1}
       }}
  """
  @spec post(struct(), String.t(), String.t(), struct()) ::
          {:ok, ContractCallObject.t()}
          | {:ok, GenericSignedTx.t()}
          | {:error, String.t()}
          | {:error, Env.t()}
  def post(connection, secret_key, network_id, %type{} = tx) do
    serialized_tx = Serialization.serialize(tx)

    signature =
      Keys.sign(
        serialized_tx,
        Keys.secret_key_to_binary(secret_key),
        network_id
      )

    signed_tx_fields = [[signature], serialized_tx]
    serialized_signed_tx = Serialization.serialize(signed_tx_fields, :signed_tx)
    encoded_signed_tx = Encoding.prefix_encode_base64("tx", serialized_signed_tx)

    with {:ok, %PostTxResponse{tx_hash: tx_hash}} <-
           TransactionApi.post_transaction(connection, %Tx{
             tx: encoded_signed_tx
           }),
         {:ok, _} = response <- await_mining(connection, tx_hash, type) do
      response
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}

      {:error, _} = error ->
        error
    end
  end

  defp await_mining(connection, tx_hash, type) do
    await_mining(connection, tx_hash, @await_attempts, type)
  end

  defp await_mining(_connection, _tx_hash, 0, _type),
    do:
      {:error,
       "Transaction wasn't mined after #{@await_attempts * @await_attempt_interval / 1000} seconds"}

  defp await_mining(connection, tx_hash, attempts, type) do
    Process.sleep(@await_attempt_interval)

    mining_status =
      case type do
        ContractCallTx ->
          TransactionApi.get_transaction_info_by_hash(connection, tx_hash)

        _ ->
          TransactionApi.get_transaction_by_hash(connection, tx_hash)
      end

    case mining_status do
      {:ok, %GenericSignedTx{block_hash: "none", block_height: -1}} ->
        await_mining(connection, tx_hash, attempts - 1, type)

      {:ok, %GenericSignedTx{}} = response ->
        response

      {:ok, %ContractCallObject{}} = response ->
        response

      {:ok, %Error{}} ->
        await_mining(connection, tx_hash, attempts - 1, type)

      {:error, %Env{} = env} ->
        {:error, env}
    end
  end

  def default_ttl, do: @default_ttl

  @doc """
  Calculates minimum fee of given transaction, depends on height and network_id

  ##  Examples:
       iex> name_pre_claim_tx =
              %AeternityNode.Model.NamePreclaimTx{
              account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
              commitment_id: "cm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
              fee: 0,
              nonce: 0,
              ttl: 0
            }
       iex> Utils.Transaction.calculate_min_fee(name_pre_claim_tx, 50000, "ae_mainnet")
         16500000000
  """

  @spec calculate_min_fee(struct(), non_neg_integer(), String.t()) ::
          non_neg_integer() | {:error, String.t()}
  def calculate_min_fee(%struct{} = tx, height, network_id)
      when struct in @struct_type and is_integer(height) and network_id in @network_id_list do
    min_gas(tx, height) * Governance.min_gas_price(height, network_id)
  end

  def calculate_min_fee(tx, height, network_id) do
    {:error,
     "#{__MODULE__} Not valid tx: #{inspect(tx)} or height: #{inspect(height)} or networkid: #{
       inspect(network_id)
     }"}
  end

  @doc """
  Calculates minimum gas needed for given transaction, also depends on height.

  ##  Examples:
       iex> spend_tx =
              %AeternityNode.Model.SpendTx{
               amount: 5018857520000000000,
               fee: 0,
               nonce: 37181,
               payload: "",
               recipient_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
               sender_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
               ttl: 0
              }
       iex> Utils.Transaction.min_gas spend_tx, 50000
         16740
  """
  @spec min_gas(struct(), non_neg_integer()) :: non_neg_integer() | {:error, String.t()}
  def min_gas(%ContractCallTx{} = tx, _height) do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
  end

  def min_gas(%ContractCreateTx{} = tx, _height) do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
  end

  def min_gas(tx, height) do
    gas_limit(tx, height)
  end

  @doc """
  Returns gas limit for given transaction, depends on height.

  ##  Examples:
        iex> oracle_register_tx =
            %AeternityNode.Model.OracleRegisterTx{
              abi_version: 196609,
              account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
              fee: 0,
              nonce: 37122,
              oracle_ttl: %AeternityNode.Model.Ttl{type: "block", value: 10},
              query_fee: 10,
              query_format: "query_format",
              response_format: "response_format",
              ttl: 10,
              vm_version: 196609
            }
        iex> Utils.Transaction.gas_limit oracle_register_tx, 5
          16581

  """
  @spec gas_limit(struct(), non_neg_integer()) :: non_neg_integer() | {:error, String.t()}
  def gas_limit(%OracleRegisterTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleExtendTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleQueryTx{query_ttl: query_ttl} = tx, height) do
    case ttl_delta(height, {query_ttl.type, query_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleRespondTx{response_ttl: response_ttl} = tx, height) do
    case ttl_delta(height, {response_ttl.type, response_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%struct{} = tx, _height)
      when struct in [
             SpendTx,
             NamePreclaimTx,
             NameClaimTx,
             NameTransferTx,
             NameRevokeTx,
             NameUpdateTx,
             ChannelCreateTx,
             ChannelCloseMutualTx,
             ChannelCloseSoloTx,
             ChannelDepositTx,
             ChannelForceProgressTx,
             ChannelSettleTx,
             ChannelSlashTx,
             ChannelSnapshotSoloTx,
             ChannelWithdrawTx
           ] do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
  end

  def gas_limit(tx, height) do
    {:error, "#{__MODULE__} Invalid #{inspect(tx)} and/or height #{inspect(height)}"}
  end

  defp ttl_delta(_height, {"delta", _value} = ttl) do
    {"delta", oracle_ttl_delta(0, ttl)}
  end

  defp ttl_delta(height, {"block", _value} = ttl) do
    case oracle_ttl_delta(height, ttl) do
      ttl_delta when is_integer(ttl_delta) ->
        {"delta", ttl_delta}

      {:error, _reason} = err ->
        err
    end
  end

  defp oracle_ttl_delta(_current_height, {"delta", d}), do: d

  defp oracle_ttl_delta(current_height, {"block", h}) when h > current_height,
    do: h - current_height

  defp oracle_ttl_delta(_current_height, {"block", _}),
    do: {:error, "#{__MODULE__} Too low height"}

  defp state_gas(tx, {"delta", ttl}) do
    tx
    |> Governance.state_gas_per_block()
    |> Governance.state_gas(ttl)
  end
end
