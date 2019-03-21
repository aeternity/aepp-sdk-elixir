defmodule AeternityNode.Model.Error do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :reason
  ]

  @type t :: %__MODULE__{
          :reason => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Error do
  def decode(value, _options) do
    value
  end
end
