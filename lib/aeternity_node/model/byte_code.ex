defmodule AeternityNode.Model.ByteCode do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :bytecode
  ]

  @type t :: %__MODULE__{
          :bytecode => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ByteCode do
  def decode(value, _options) do
    value
  end
end
