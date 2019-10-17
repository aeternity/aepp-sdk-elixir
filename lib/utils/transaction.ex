defmodule AeppSDK.Utils.Transaction do
  @moduledoc """
  Transaction AeppSDK.Utils.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """
  alias AeppSDK.Account, as: AccountApi
  alias AeppSDK.{Client, Contract, GeneralizedAccount}
  alias AeppSDK.Utils.{Encoding, Governance, Keys, Serialization}

  alias AeternityNode.Api.Transaction, as: TransactionApi

  alias AeternityNode.Model.{
    Account,
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelCreateTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx,
    ContractCallObject,
    ContractCallTx,
    ContractCreateTx,
    Error,
    GenericSignedTx,
    NameClaimTx,
    NamePreclaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx,
    OracleExtendTx,
    OracleQueryTx,
    OracleRegisterTx,
    OracleRespondTx,
    PostTxResponse,
    SpendTx,
    Tx,
    TxInfoObject
  }

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
    ContractCreateTx,
    ChannelCreateTx,
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx
  ]

  @network_id_list ["ae_mainnet", "ae_uat"]

  @await_attempts 25
  @await_attempt_interval 200
  @default_ttl 0
  @dummy_fee 0
  @default_payload ""
  @fortuna_height 90_800
  @fee_calculation_times 5

  @type tx_types ::
          SpendTx.t()
          | OracleRegisterTx.t()
          | OracleQueryTx.t()
          | OracleRespondTx.t()
          | OracleExtendTx.t()
          | NamePreclaimTx.t()
          | NameClaimTx.t()
          | NameTransferTx.t()
          | NameRevokeTx.t()
          | NameUpdateTx.t()
          | ContractCallTx.t()
          | ContractCreateTx.t()

  @spec default_ttl :: non_neg_integer()
  def default_ttl, do: @default_ttl

  @spec default_payload :: String.t()
  def default_payload, do: @default_payload

  @spec dummy_fee :: non_neg_integer()
  def dummy_fee, do: @dummy_fee

  @spec default_await_attempts :: non_neg_integer()
  def default_await_attempts, do: @await_attempts

  @spec default_await_attempt_interval :: non_neg_integer()
  def default_await_attempt_interval, do: @await_attempt_interval

  @spec default_fee_calculation_times :: non_neg_integer()
  def default_fee_calculation_times, do: @fee_calculation_times

  @doc """
  Serialize the list of fields to RLP transaction binary, sign it with the private key and network ID,
  add calculated minimum fee and post it to the node.

  ## Example
      iex> spend_tx = %AeternityNode.Model.SpendTx{
                          amount: 10_000,
                          fee: 16_680_000_000,
                          nonce: 1,
                          payload: "",
                          recipient_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
                          sender_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                          ttl: 0
                        }
      iex> AeppSDK.Utils.Transaction.post(client, spend_tx, :no_auth, :one_signature)
      {:ok,
       %{
         block_hash: "mh_2wRRkfzcHd24cGbqdqaLAhxgpv4iMB8y1Cp5n9FAfhvDZJ7Qh",
         block_height: 149,
         tx_hash: "th_umEMGk2S1EtkeAZCVHXDoTqQMdMawK9R9j1yvDZWjvKmstg5c"
       }}
  """
  @spec post(
          Client.t(),
          tx_types(),
          atom() | list(),
          list() | atom()
        ) :: {:ok, map()} | {:error, String.t()} | {:error, Env.t()}
  def post(
        %Client{
          connection: connection,
          keypair: %{secret: secret_key},
          network_id: network_id
        },
        tx,
        :no_auth,
        signatures_list
      ) do
    type = Map.get(tx, :__struct__, :no_type)
    serialized_tx = Serialization.serialize(tx)

    signature =
      Keys.sign(
        serialized_tx,
        Keys.secret_key_to_binary(secret_key),
        network_id
      )

    signed_tx_fields =
      case signatures_list do
        :one_signature -> [[signature], serialized_tx]
        _ -> [signatures_list, serialized_tx]
      end

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

      {:error, _} = error ->
        error
    end
  end

  def post(
        %Client{
          connection: connection,
          keypair: %{public: public_key},
          gas_price: gas_price,
          network_id: network_id
        } = client,
        tx,
        auth_opts,
        _signatures_list
      ) do
    tx = %{tx | nonce: 0}
    type = Map.get(tx, :__struct__, :no_type)

    with {:ok, %{kind: "generalized", auth_fun: auth_fun, contract_id: contract_id}} <-
           AccountApi.get(client, public_key),
         {:ok, %{abi_version: abi_version}} <- Contract.get(client, contract_id),
         :ok <- ensure_auth_opts(auth_opts),
         {:ok, calldata} =
           Contract.create_calldata(
             Keyword.get(auth_opts, :auth_contract_source),
             auth_fun,
             Keyword.get(auth_opts, :auth_args)
           ),
         serialized_tx = wrap_in_empty_signed_tx(tx),
         meta_tx_dummy_fee = %{
           ga_id: public_key,
           auth_data: calldata,
           abi_version: abi_version,
           fee: @dummy_fee,
           gas: Keyword.get(auth_opts, :gas, GeneralizedAccount.default_gas()),
           gas_price: Keyword.get(auth_opts, :gas_price, gas_price),
           ttl: Keyword.get(auth_opts, :ttl, @default_ttl),
           tx: serialized_tx
         },
         meta_tx = %{
           meta_tx_dummy_fee
           | fee:
               Keyword.get(
                 auth_opts,
                 :fee,
                 calculate_fee(
                   tx,
                   @fortuna_height,
                   network_id,
                   @dummy_fee,
                   meta_tx_dummy_fee.gas_price
                 )
               )
         },
         serialized_meta_tx = wrap_in_empty_signed_tx(meta_tx),
         encoded_signed_tx = Encoding.prefix_encode_base64("tx", serialized_meta_tx),
         {:ok, %PostTxResponse{tx_hash: tx_hash}} <-
           TransactionApi.post_transaction(connection, %Tx{
             tx: encoded_signed_tx
           }),
         {:ok, _} = response <- await_mining(connection, tx_hash, type) do
      response
    else
      {:ok, %{kind: "basic"}} ->
        {:error, "Account isn't generalized"}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Calculate the fee of the transaction.

  ## Example
      iex> spend_tx = %AeternityNode.Model.SpendTx{
                          amount: 40_000_000,
                          fee: 0,
                          nonce: 10_624,
                          payload: "",
                          recipient_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                          sender_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                          ttl: 0
                        }
      iex> AeppSDK.Utils.Transaction.calculate_fee(spend_tx, 51_900, "ae_uat", 0, 1_000_000)
      16660000000
  """
  @spec calculate_fee(
          tx_types(),
          non_neg_integer(),
          String.t(),
          atom() | non_neg_integer(),
          non_neg_integer()
        ) :: non_neg_integer()
  def calculate_fee(tx, height, _network_id, @dummy_fee, gas_price) when gas_price > 0 do
    min_gas(tx, height) * gas_price
  end

  def calculate_fee(_tx, _height, _network_id, fee, _gas_price) when fee > 0 do
    fee
  end

  def calculate_fee(_tx, _height, _network_id, fee, gas_price) do
    {:error, "#{__MODULE__}: Incorrect fee: #{fee} or gas price: #{gas_price}"}
  end

  @doc """
  Calculates minimum fee of given transaction, depends on height and network_id

  ## Example
      iex> name_pre_claim_tx = %AeternityNode.Model.NamePreclaimTx{
                                   account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
                                   commitment_id: "cm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
                                   fee: 0,
                                   nonce: 0,
                                   ttl: 0
                                 }
      iex> AeppSDK.Utils.Transaction.calculate_min_fee(name_pre_claim_tx, 50_000, "ae_mainnet")
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

  ## Example
      iex> spend_tx = %AeternityNode.Model.SpendTx{
                          amount: 5_018_857_520_000_000_000,
                          fee: 0,
                          nonce: 37181,
                          payload: "",
                          recipient_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
                          sender_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
                          ttl: 0
                        }
      iex> AeppSDK.Utils.Transaction.min_gas(spend_tx, 50_000)
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

  ## Example
      iex> oracle_register_tx = %AeternityNode.Model.OracleRegisterTx{
                                    abi_version: 0x60001,
                                    account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
                                    fee: 0,
                                    nonce: 37_122,
                                    oracle_ttl: %AeternityNode.Model.Ttl{type: :absolute, value: 10},
                                    query_fee: 10,
                                    query_format: "query_format",
                                    response_format: "response_format",
                                    ttl: 10
                                  }
      iex> AeppSDK.Utils.Transaction.gas_limit(oracle_register_tx, 5)
      16581
  """
  @spec gas_limit(struct(), non_neg_integer()) :: non_neg_integer() | {:error, String.t()}
  def gas_limit(%OracleRegisterTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {:relative, _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleExtendTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {:relative, _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleQueryTx{query_ttl: query_ttl} = tx, height) do
    case ttl_delta(height, {query_ttl.type, query_ttl.value}) do
      {:relative, _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() + state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleRespondTx{response_ttl: response_ttl} = tx, height) do
    case ttl_delta(height, {response_ttl.type, response_ttl.value}) do
      {:relative, _d} = ttl ->
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
             ChannelWithdrawTx,
             ContractCreateTx,
             ContractCallTx
           ] do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
      Governance.gas(tx)
  end

  def gas_limit(tx, _height) do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
      Governance.gas(tx)
  end

  @doc """
  Signs the transaction.

  ## Example
      iex> spend_tx = %AeternityNode.Model.SpendTx{
                          amount: 1_000_000_000_000,
                          fee: 0,
                          nonce: 1,
                          payload: "",
                          recipient_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
                          sender_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                          ttl: 0
                        }
      iex> AeppSDK.Utils.Transaction.sign_tx(spend_tx, client)
      {:ok,
       [
         %AeternityNode.Model.SpendTx{
           amount: 1000000000000,
           fee: 0,
           nonce: 1,
           payload: "",
           recipient_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
           sender_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
           ttl: 0
         },
         <168, 173, 62, 192, 198, 163, 29, 224, 83, 235, 68, 152, 82, 151, 77, 68,
          228, 138, 200, 45, 15, 74, 125, 222, 45, 150, 114, 79, 84, 160, 83, 255,
          63, 165, 45, 146, 164, 168, 144, 116, 200, 253, 80, 119, 6, 147, ...>>
       ]}
  """
  @spec sign_tx(tx_types(), Client.t(), list() | :no_opts) :: {:ok, list()} | {:error, String.t()}
  def sign_tx(tx, client, auth_opts \\ :no_opts) do
    sign_tx_(tx, client, auth_opts)
  end

  @doc """
  Calculates fee for given transaction `n` times.

  ## Example
      iex> spend_tx = %AeternityNode.Model.SpendTx{
                          amount: 1_000_000_000_000,
                          fee: 0,
                          nonce: 1,
                          payload: "",
                          recipient_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
                          sender_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                          ttl: 0
                        }
      iex> AeppSDK.Utils.Transaction.calculate_n_times_fee(spend_tx, 58_336, "ae_uat", 0, 1_000_000, 5)
      16740000000
  """
  @spec calculate_n_times_fee(
          tx_types,
          non_neg_integer(),
          String.t(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: non_neg_integer()
  def calculate_n_times_fee(tx, height, network_id, fee, gas_price, times) do
    calculate_fee_n_times(tx, height, network_id, fee, gas_price, times, 0)
  end

  @doc false
  def await_mining(connection, tx_hash, type) do
    await_mining(connection, tx_hash, @await_attempts, type)
  end

  @doc false
  def await_mining(_connection, _tx_hash, 0, _type),
    do:
      {:error,
       "Transaction wasn't mined after #{@await_attempts * @await_attempt_interval / 1_000} seconds"}

  @doc false
  def await_mining(connection, tx_hash, attempts, type) do
    Process.sleep(@await_attempt_interval)

    mining_status =
      case type do
        ContractCallTx ->
          TransactionApi.get_transaction_info_by_hash(connection, tx_hash)

        ContractCreateTx ->
          TransactionApi.get_transaction_info_by_hash(connection, tx_hash)

        _ ->
          TransactionApi.get_transaction_by_hash(connection, tx_hash)
      end

    case mining_status do
      {:ok, %GenericSignedTx{block_hash: "none", block_height: -1}} ->
        await_mining(connection, tx_hash, attempts - 1, type)

      {:ok, %GenericSignedTx{block_hash: block_hash, block_height: block_height, hash: tx_hash}} ->
        {:ok, %{block_hash: block_hash, block_height: block_height, tx_hash: tx_hash}}

      {:ok,
       %TxInfoObject{
         call_info: %ContractCallObject{
           log: log,
           return_value: return_value,
           return_type: return_type
         }
       }} ->
        {:ok, %GenericSignedTx{block_hash: block_hash, block_height: block_height, hash: tx_hash}} =
          TransactionApi.get_transaction_by_hash(connection, tx_hash)

        {:ok,
         %{
           block_hash: block_hash,
           block_height: block_height,
           tx_hash: tx_hash,
           return_value: return_value,
           return_type: return_type,
           log: log
         }}

      {:ok, %Error{}} ->
        await_mining(connection, tx_hash, attempts - 1, type)

      {:error, %Env{} = env} ->
        {:error, env}
    end
  end

  defp calculate_fee_n_times(_tx, _height, _network_id, _fee, _gas_price, 0, acc) do
    acc
  end

  defp calculate_fee_n_times(tx, height, network_id, fee, gas_price, times, _acc) do
    case fee do
      0 ->
        acc = calculate_fee(tx, height, network_id, 0, gas_price)

        calculate_fee_n_times(
          %{tx | fee: acc},
          height,
          network_id,
          fee,
          gas_price,
          times - 1,
          acc
        )

      fee ->
        calculate_fee_n_times(%{tx | fee: fee}, height, network_id, fee, gas_price, 0, fee)
    end
  end

  defp ttl_delta(_height, {:relative, _value} = ttl) do
    {:relative, oracle_ttl_delta(0, ttl)}
  end

  defp ttl_delta(height, {:absolute, _value} = ttl) do
    case oracle_ttl_delta(height, ttl) do
      ttl_delta when is_integer(ttl_delta) ->
        {:relative, ttl_delta}

      {:error, _reason} = err ->
        err
    end
  end

  defp sign_tx_(
         tx,
         %Client{
           keypair: %{public: public_key, secret: secret_key},
           network_id: network_id
         } = client,
         :no_opts
       )
       when is_map(tx) do
    case AccountApi.get(client, public_key) do
      {:ok, %{kind: "basic"}} ->
        serialized_tx = Serialization.serialize(tx)

        signature =
          Keys.sign(
            serialized_tx,
            Keys.secret_key_to_binary(secret_key),
            network_id
          )

        {:ok, [tx, signature]}

      {:ok, %{kind: other}} ->
        {:error, "Account can't be authorized as Basic, as it is #{inspect(other)} type"}

      {:error, err} ->
        {:error, "Unexpected error: #{inspect(err)} "}
    end
  end

  defp sign_tx_(
         tx,
         %Client{
           keypair: %{public: public_key},
           gas_price: gas_price,
           network_id: network_id
         } = client,
         auth_opts
       ) do
    with {:ok, %{kind: "generalized", auth_fun: auth_fun, contract_id: contract_id}} <-
           AccountApi.get(client, public_key),
         :ok <- ensure_auth_opts(auth_opts),
         {:ok, %{vm_version: vm_version, abi_version: abi_version}} <-
           Contract.get(client, contract_id),
         {:ok, calldata} =
           Contract.create_calldata(
             Keyword.get(auth_opts, :auth_contract_source),
             auth_fun,
             Keyword.get(auth_opts, :auth_args),
             Contract.get_vm(vm_version)
           ),
         serialized_tx = wrap_in_empty_signed_tx(tx),
         meta_tx_dummy_fee <- %{
           ga_id: public_key,
           auth_data: calldata,
           abi_version: abi_version,
           fee: @dummy_fee,
           gas: Keyword.get(auth_opts, :gas, GeneralizedAccount.default_gas()),
           gas_price: Keyword.get(auth_opts, :gas_price, gas_price),
           ttl: Keyword.get(auth_opts, :ttl, @default_ttl),
           tx: serialized_tx
         },
         meta_tx <- %{
           meta_tx_dummy_fee
           | fee:
               Keyword.get(
                 auth_opts,
                 :fee,
                 calculate_fee(
                   tx,
                   @fortuna_height,
                   network_id,
                   @dummy_fee,
                   meta_tx_dummy_fee.gas_price
                 )
               )
         } do
      {:ok, [tx, meta_tx, []]}
    else
      {:ok, %Account{kind: "basic"}} ->
        {:error, "Account isn't generalized"}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end

  defp oracle_ttl_delta(_current_height, {:relative, d}), do: d

  defp oracle_ttl_delta(current_height, {:absolute, h}) when h > current_height,
    do: h - current_height

  defp oracle_ttl_delta(_current_height, {:absolute, _}),
    do: {:error, "#{__MODULE__} Too low height"}

  defp state_gas(tx, {:relative, ttl}) do
    tx
    |> Governance.state_gas_per_block()
    |> Governance.state_gas(ttl)
  end

  defp wrap_in_empty_signed_tx(tx) do
    serialized_tx = Serialization.serialize(tx)
    signed_tx_fields = [[], serialized_tx]
    Serialization.serialize(signed_tx_fields, :signed_tx)
  end

  defp ensure_auth_opts(auth_opts) do
    if Keyword.has_key?(auth_opts, :auth_contract_source) &&
         Keyword.has_key?(auth_opts, :auth_args) do
      :ok
    else
      {:error, "Authorization source and function arguments are required"}
    end
  end
end
