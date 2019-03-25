defmodule AeternityNode.Model.OffChainTransfer do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :op,
    :from,
    :to,
    :am
  ]

  @type t :: %__MODULE__{
          :op => String.t(),
          :from => String.t(),
          :to => String.t(),
          :am => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainTransfer do
  def decode(value, _options) do
    value
  end
end
