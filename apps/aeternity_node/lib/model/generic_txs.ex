defmodule AeternityNode.Model.GenericTxs do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :transactions
  ]

  @type t :: %__MODULE__{
          :transactions => [GenericSignedTx]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.GenericTxs do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:transactions, :list, AeternityNode.Model.GenericSignedTx, options)
  end
end
