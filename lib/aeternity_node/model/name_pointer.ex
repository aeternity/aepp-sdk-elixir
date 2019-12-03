defmodule AeternityNode.Model.NamePointer do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :key,
    :id
  ]

  @type t :: %__MODULE__{
          :key => String.t(),
          :id => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NamePointer do
  def decode(value, _options) do
    value
  end
end
