defmodule AeternityNode.Model.UnsignedTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :tx
  ]

  @type t :: %__MODULE__{
          :tx => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.UnsignedTx do
  def decode(value, _options) do
    value
  end
end
