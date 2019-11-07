defmodule AeternityNode.Model.GaMetaTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :ga_id,
    :abi_version,
    :gas,
    :gas_price,
    :fee,
    :ttl,
    :auth_data,
    :tx
  ]

  @type t :: %__MODULE__{
          :ga_id => String.t(),
          :abi_version => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :auth_data => String.t(),
          :tx => GenericSignedTx
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.GaMetaTx do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:tx, :struct, AeternityNode.Model.GenericSignedTx, options)
  end
end
