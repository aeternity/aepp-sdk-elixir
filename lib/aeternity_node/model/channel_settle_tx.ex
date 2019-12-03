defmodule AeternityNode.Model.ChannelSettleTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :channel_id,
    :from_id,
    :initiator_amount_final,
    :responder_amount_final,
    :ttl,
    :fee,
    :nonce
  ]

  @type t :: %__MODULE__{
          :channel_id => String.t(),
          :from_id => String.t(),
          :initiator_amount_final => integer(),
          :responder_amount_final => integer(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelSettleTx do
  def decode(value, _options) do
    value
  end
end
