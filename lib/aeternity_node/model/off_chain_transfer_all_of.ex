defmodule AeternityNode.Model.OffChainTransferAllOf do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :from,
    :to,
    :amount
  ]

  @type t :: %__MODULE__{
          :from => String.t(),
          :to => String.t(),
          :amount => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainTransferAllOf do
  def decode(value, _options) do
    value
  end
end
