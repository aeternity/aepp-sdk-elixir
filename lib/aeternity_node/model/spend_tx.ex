defmodule AeternityNode.Model.SpendTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :recipient_id,
    :amount,
    :fee,
    :ttl,
    :sender_id,
    :nonce,
    :payload
  ]

  @type t :: %__MODULE__{
          :recipient_id => String.t(),
          :amount => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :sender_id => String.t(),
          :nonce => integer() | nil,
          :payload => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.SpendTx do
  def decode(value, _options) do
    value
  end
end
