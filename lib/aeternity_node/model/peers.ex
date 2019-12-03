defmodule AeternityNode.Model.Peers do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :peers,
    :blocked
  ]

  @type t :: %__MODULE__{
          :peers => [String],
          :blocked => [String]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Peers do
  def decode(value, _options) do
    value
  end
end
