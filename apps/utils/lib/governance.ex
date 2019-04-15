defmodule Utils.Governance do
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
    ChannelCreateTx,
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx,
    ContractCallTx,
    ContractCreateTx
  }

  @tx_base_gas 15_000
  @byte_gas 20
  # 32000 as `GCREATE` i.e. an oracle-related state object costs per year as much as it costs to indefinitely create an account.
  @oracle_state_gas_per_year 32_000
  @expected_block_mine_rate_minutes 3
  @expected_blocks_in_a_year_floor 175_200 = div(60 * 24 * 365, @expected_block_mine_rate_minutes)

  def tx_base_gas(%ContractCallTx{}), do: 30 * @tx_base_gas
  def tx_base_gas(%ContractCreateTx{}), do: 5 * @tx_base_gas
  def tx_base_gas(%SpendTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelDepositTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelCloseMutualTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelCloseSoloTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelCreateTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelForceProgressTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelSlashTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelSettleTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelSnapshotSoloTx{}), do: @tx_base_gas
  def tx_base_gas(%ChannelWithdrawTx{}), do: @tx_base_gas
  def tx_base_gas(%NamePreclaimTx{}), do: @tx_base_gas
  def tx_base_gas(%NameClaimTx{}), do: @tx_base_gas
  def tx_base_gas(%NameTransferTx{}), do: @tx_base_gas
  def tx_base_gas(%NameRevokeTx{}), do: @tx_base_gas
  def tx_base_gas(%NameUpdateTx{}), do: @tx_base_gas
  def tx_base_gas(%OracleRegisterTx{}), do: @tx_base_gas
  def tx_base_gas(%OracleQueryTx{}), do: @tx_base_gas
  def tx_base_gas(%OracleRespondTx{}), do: @tx_base_gas
  def tx_base_gas(%OracleExtendTx{}), do: @tx_base_gas
  def byte_gas(), do: @byte_gas

  def state_gas_per_block(%OracleRegisterTx{}),
    do: {@oracle_state_gas_per_year, @expected_blocks_in_a_year_floor}

  def state_gas_per_block(%OracleQueryTx{}), do: state_gas_per_block(%OracleRegisterTx{})
  def state_gas_per_block(%OracleRespondTx{}), do: state_gas_per_block(%OracleRegisterTx{})
  def state_gas_per_block(%OracleExtendTx{}), do: state_gas_per_block(%OracleRegisterTx{})

  def state_gas({part, whole}, n_key_blocks)
      when is_integer(whole) and whole > 0 and is_integer(part) and part >= 0 and
             is_integer(n_key_blocks) and n_key_blocks >= 0 do
    tmp = n_key_blocks * part
    div(tmp + (whole - 1), whole)
  end

  @spec min_gas_price(non_neg_integer(), String.t()) :: 1 | 1_000_000
  def min_gas_price(height, network_id)
      when is_integer(height) and height >= 0 and is_binary(network_id) do
    case protocol_effective_at_height(height, network_id) do
      1 -> 1
      _ -> 1_000_000
    end
  end

  defp protocol_effective_at_height(height, "ae_mainnet") when height < 47_800, do: 1

  defp protocol_effective_at_height(height, "ae_mainnet") when height >= 47_800, do: 2

  defp protocol_effective_at_height(height, "ae_uat") when height < 40_900, do: 1

  defp protocol_effective_at_height(height, "ae_uat") when height >= 40_900, do: 2
end
