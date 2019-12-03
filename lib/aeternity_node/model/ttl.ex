defmodule AeternityNode.Model.Ttl do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :type,
    :value
  ]

  @type t :: %__MODULE__{
          :type => String.t(),
          :value => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Ttl do
  def decode(value, _options) do
    value
  end
end
