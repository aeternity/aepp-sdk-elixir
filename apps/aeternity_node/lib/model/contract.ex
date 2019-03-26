defmodule AeternityNode.Model.Contract do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :code,
    :options
  ]

  @type t :: %__MODULE__{
          :code => String.t(),
          :options => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Contract do
  def decode(value, _options) do
    value
  end
end
