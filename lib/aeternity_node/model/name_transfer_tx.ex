defmodule AeternityNode.Model.NameTransferTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :name_id,
    :recipient_id,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :name_id => String.t(),
          :recipient_id => String.t(),
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameTransferTx do
  def decode(value, _options) do
    value
  end
end
