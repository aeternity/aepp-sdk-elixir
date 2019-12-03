defmodule AeternityNode.Model.PoI do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :poi
  ]

  @type t :: %__MODULE__{
          :poi => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.PoI do
  def decode(value, _options) do
    value
  end
end
