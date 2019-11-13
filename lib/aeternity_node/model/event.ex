defmodule AeternityNode.Model.Event do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :address,
    :topics,
    :data
  ]

  @type t :: %__MODULE__{
          :address => String.t(),
          :topics => [Integer],
          :data => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Event do
  def decode(value, _options) do
    value
  end
end
