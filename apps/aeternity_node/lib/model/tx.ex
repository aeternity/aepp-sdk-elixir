defmodule AeternityNode.Model.Tx do
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

defimpl Poison.Decoder, for: AeternityNode.Model.Tx do
  def decode(value, _options) do
    value
  end
end
