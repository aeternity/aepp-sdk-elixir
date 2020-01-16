defmodule AeternityNode.Model.InlineResponse2002 do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :count
  ]

  @type t :: %__MODULE__{
          :count => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.InlineResponse2002 do
  def decode(value, _options) do
    value
  end
end
