defmodule Utils.Transaction do
  @moduledoc """
  Transaction utils and helper functions.
  """

  alias Utils.{Serialization, Governance}

  alias AeternityNode.Model.{
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
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleExtendTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleQueryTx{query_ttl: query_ttl} = tx, height) do
    case ttl_delta(height, {query_ttl.type, query_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  def gas_limit(%OracleRespondTx{response_ttl: response_ttl} = tx, height) do
    case ttl_delta(height, {response_ttl.type, response_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

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
