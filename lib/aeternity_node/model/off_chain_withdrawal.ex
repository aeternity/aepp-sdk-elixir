defmodule AeternityNode.Model.OffChainWithdrawal do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :op,
    :to,
    :amount
  ]

  @type t :: %__MODULE__{
          :op => String.t(),
          :to => String.t(),
          :amount => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainWithdrawal do
  def decode(value, _options) do
    value
  end
end
