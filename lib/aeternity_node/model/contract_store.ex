defmodule AeternityNode.Model.ContractStore do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :store
  ]

  @type t :: %__MODULE__{
          :store => [ContractStoreStore]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractStore do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:store, :list, AeternityNode.Model.ContractStoreStore, options)
  end
end
