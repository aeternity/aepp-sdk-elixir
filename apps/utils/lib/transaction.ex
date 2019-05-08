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
      iex> network_id = "ae_uat"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> tx = %AeternityNode.Model.ContractCreateTx{
        abi_version: 0x01,
        amount: 0,
        call_data: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 226, 35, 29, 108, 223, 201, 57, 22, 222, 76,
          179, 169, 133, 123, 246, 92, 244, 15, 194, 86, 244, 161, 73, 139, 63, 126,
          124, 152, 12, 25, 147, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42>>,
        code: <<249, 4, 242, 70, 1, 160, 170, 251, 126, 179, 95, 98, 126, 171, 60,
          197, 60, 173, 35, 91, 99, 235, 181, 15, 37, 55, 98, 52, 167, 48, 237, 218,
          10, 163, 53, 36, 206, 87, 249, 3, 196, 249, 1, 51, 160, 112, 194, 27, 63,
          171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82, 86,
          82, 53, 206, 145, 155, 60, 13, 206, 214, 183, 62, 141, 97, 100, 100, 95,
          116, 111, 95, 110, 117, 109, 98, 101, 114, 184, 192, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 160, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 184, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 249, 2,
          139, 160, 226, 35, 29, 108, 223, 201, 57, 22, 222, 76, 179, 169, 133, 123,
          246, 92, 244, 15, 194, 86, 244, 161, 73, 139, 63, 126, 124, 152, 12, 25,
          147, 68, 132, 105, 110, 105, 116, 184, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 160, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 185, 1, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 192, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 1, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 64, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 1, 128, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
          255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 185, 1, 5, 98, 0, 0, 100,
          98, 0, 0, 151, 145, 128, 128, 128, 81, 127, 112, 194, 27, 63, 171, 248, 210,
          119, 144, 238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82, 86, 82, 53, 206,
          145, 155, 60, 13, 206, 214, 183, 62, 20, 98, 0, 0, 242, 87, 80, 128, 81,
          127, 226, 35, 29, 108, 223, 201, 57, 22, 222, 76, 179, 169, 133, 123, 246,
          92, 244, 15, 194, 86, 244, 161, 73, 139, 63, 126, 124, 152, 12, 25, 147, 68,
          20, 98, 0, 0, 170, 87, 80, 96, 1, 25, 81, 0, 91, 96, 0, 25, 89, 96, 32, 1,
          144, 129, 82, 96, 32, 144, 3, 96, 0, 89, 144, 129, 82, 129, 82, 89, 96, 32,
          1, 144, 129, 82, 96, 32, 144, 3, 96, 3, 129, 82, 144, 89, 96, 0, 81, 89, 82,
          96, 0, 82, 96, 0, 243, 91, 96, 0, 128, 82, 96, 0, 243, 91, 128, 96, 0, 81,
          81, 1, 144, 80, 144, 86, 91, 96, 32, 1, 81, 81, 131, 146, 80, 128, 145, 80,
          80, 128, 89, 144, 129, 82, 89, 96, 32, 1, 144, 129, 82, 96, 32, 144, 3, 96,
          0, 25, 89, 96, 32, 1, 144, 129, 82, 96, 32, 144, 3, 96, 0, 89, 144, 129, 82,
          129, 82, 89, 96, 32, 1, 144, 129, 82, 96, 32, 144, 3, 96, 3, 129, 82, 129,
          82, 144, 80, 144, 86, 91, 96, 32, 1, 81, 81, 144, 80, 89, 80, 128, 145, 80,
          80, 98, 0, 0, 159, 86>>,
        deposit: 0,
        fee: 10422000000000000,
        gas: 1000000,
        gas_price: 1000000000,
        nonce: 9429,
        owner_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
        ttl: 0,
        vm_version: 0x03
      }
      iex> Utils.Transaction.post(connection, privkey, network_id, tx)
      {:ok,
       %{
         block_hash: "mh_29ZNDHkaa1k54Gr9HqFDJ3ubDg7Wi6yJEsfuCy9qKQEjxeHdH4",
         block_height: 68240,
         hash: "th_gfVPUw5zerDAkokfanFrhoQk9WDJaCdbwS6dGxVQWZce7tU3j"
       }}
  """
  @spec post(struct(), String.t(), String.t(), struct()) ::
          {:ok, map()} | {:error, String.t()} | {:error, Env.t()}
  def post(connection, privkey, network_id, %type{} = tx) do
    serialized_tx = Serialization.serialize(tx)

    signature =
      Keys.sign(
        serialized_tx,
        Keys.privkey_to_binary(privkey),
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
    :timer.sleep(@await_attempt_interval)

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

      {:ok, %GenericSignedTx{block_hash: block_hash, block_height: block_height, hash: tx_hash}} ->
        {:ok, %{block_hash: block_hash, block_height: block_height, tx_hash: tx_hash}}

      {:ok, %ContractCallObject{return_value: return_value, return_type: return_type}} ->
        %GenericSignedTx{block_hash: block_hash, block_height: block_height, hash: tx_hash} =
          TransactionApi.get_transaction_by_hash(connection, tx_hash)

        {:ok,
         %{
           block_hash: block_hash,
           block_height: block_height,
           tx_hash: tx_hash,
           return_value: return_value,
           return_type: return_type
         }}

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
              oracle_ttl: %AeternityNode.Model.Ttl{type: :absolute, value: 10},
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
             ChannelWithdrawTx
           ] do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
  end

  def gas_limit(tx, height) do
    {:error, "#{__MODULE__} Invalid #{inspect(tx)} and/or height #{inspect(height)}"}
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
end
