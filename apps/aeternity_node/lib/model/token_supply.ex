defmodule AeternityNode.Model.TokenSupply do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :accounts,
    :contracts,
    :contract_oracles,
    :locked,
    :oracles,
    :oracle_queries,
    :pending_rewards,
    :total
  ]

  @type t :: %__MODULE__{
          :accounts => integer() | nil,
          :contracts => integer() | nil,
          :contract_oracles => integer() | nil,
          :locked => integer() | nil,
          :oracles => integer() | nil,
          :oracle_queries => integer() | nil,
          :pending_rewards => integer() | nil,
          :total => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.TokenSupply do
  def decode(value, _options) do
    value
  end
end
