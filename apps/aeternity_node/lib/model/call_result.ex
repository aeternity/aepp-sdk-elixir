defmodule AeternityNode.Model.CallResult do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :out
  ]

  @type t :: %__MODULE__{
          :out => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.CallResult do
  def decode(value, _options) do
    value
  end
end
