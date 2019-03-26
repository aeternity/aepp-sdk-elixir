defmodule AeternityNode.Model.Account do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :balance,
    :nonce
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :balance => integer(),
          :nonce => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Account do
  def decode(value, _options) do
    value
  end
end
