defmodule AeternityNode.Model.NameUpdateTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :name_id,
    :name_ttl,
    :pointers,
    :client_ttl,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :name_id => String.t(),
          :name_ttl => integer(),
          :pointers => [NamePointer],
          :client_ttl => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameUpdateTxJson do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:pointers, :list, AeternityNode.Model.NamePointer, options)
  end
end
