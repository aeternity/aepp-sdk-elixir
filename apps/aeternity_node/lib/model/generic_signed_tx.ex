defmodule AeternityNode.Model.GenericSignedTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :tx,
    :block_height,
    :block_hash,
    :hash,
    :signatures
  ]

  @type t :: %__MODULE__{
          :tx => GenericTx,
          :block_height => integer(),
          :block_hash => String.t(),
          :hash => String.t(),
          :signatures => [String.t()]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.GenericSignedTx do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:tx, :struct, AeternityNode.Model.GenericTx, options)
  end
end
