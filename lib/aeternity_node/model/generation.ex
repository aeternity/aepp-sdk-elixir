defmodule AeternityNode.Model.Generation do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :key_block,
    :micro_blocks
  ]

  @type t :: %__MODULE__{
          :key_block => KeyBlock,
          :micro_blocks => [String]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Generation do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:key_block, :struct, AeternityNode.Model.KeyBlock, options)
  end
end
