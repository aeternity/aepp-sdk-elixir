defmodule AeternityNode.Model.InlineResponse2003 do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :pubkey
  ]

  @type t :: %__MODULE__{
          :pubkey => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.InlineResponse2003 do
  def decode(value, _options) do
    value
  end
end
