defmodule AeternityNode.Model.InlineResponse2001 do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :height
  ]

  @type t :: %__MODULE__{
          :height => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.InlineResponse2001 do
  def decode(value, _options) do
    value
  end
end
