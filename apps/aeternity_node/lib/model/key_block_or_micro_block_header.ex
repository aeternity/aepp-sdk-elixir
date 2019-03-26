defmodule AeternityNode.Model.KeyBlockOrMicroBlockHeader do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :key_block,
    :micro_block
  ]

  @type t :: %__MODULE__{
          :key_block => KeyBlock | nil,
          :micro_block => MicroBlockHeader | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.KeyBlockOrMicroBlockHeader do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:key_block, :struct, AeternityNode.Model.KeyBlock, options)
    |> deserialize(:micro_block, :struct, AeternityNode.Model.MicroBlockHeader, options)
  end
end
