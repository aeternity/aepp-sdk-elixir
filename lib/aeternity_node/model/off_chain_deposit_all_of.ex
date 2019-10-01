defmodule AeternityNode.Model.OffChainDepositAllOf do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :from,
    :amount
  ]

  @type t :: %__MODULE__{
          :from => String.t(),
          :amount => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainDepositAllOf do
  def decode(value, _options) do
    value
  end
end
