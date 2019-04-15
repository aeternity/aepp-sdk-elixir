defmodule Utils.Transaction do
  alias Utils.{Serialization, Governance}

  alias AeternityNode.Model.{
    ContractCallTx,
    ContractCreateTx,
    OracleRegisterTx,
    OracleRespondTx,
    OracleExtendTx,
    OracleQueryTx
  }

  def calculate_min_fee(tx, height, network_id) when is_integer(height) do
    min_gas(tx, height) * Governance.min_gas_price(height, network_id)
  end

  defp min_gas(%ContractCallTx{} = tx, _height) do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
  end

  defp min_gas(%ContractCreateTx{} = tx, _height) do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
  end

  defp min_gas(tx, height) do
    gas_limit(tx, height)
  end

  defp gas_limit(%OracleRegisterTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  defp gas_limit(%OracleExtendTx{oracle_ttl: oracle_ttl} = tx, height) do
    case ttl_delta(height, {oracle_ttl.type, oracle_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  defp gas_limit(%OracleQueryTx{query_ttl: query_ttl} = tx, height) do
    case ttl_delta(height, {query_ttl.type, query_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  defp gas_limit(%OracleRespondTx{response_ttl: response_ttl} = tx, height) do
    case ttl_delta(height, {response_ttl.type, response_ttl.value}) do
      {"delta", _d} = ttl ->
        Governance.tx_base_gas(tx) +
          byte_size(Serialization.serialize(tx)) * Governance.byte_gas() +
          state_gas(tx, ttl)

      {:error, _reason} ->
        0
    end
  end

  defp gas_limit(tx, height) do
    Governance.tx_base_gas(tx) + byte_size(Serialization.serialize(tx)) * Governance.byte_gas()
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
