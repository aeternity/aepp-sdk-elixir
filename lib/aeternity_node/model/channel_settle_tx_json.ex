defmodule AeternityNode.Model.ChannelSettleTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :channel_id,
    :from_id,
    :initiator_amount_final,
    :responder_amount_final,
    :ttl,
    :fee,
    :nonce
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :channel_id => String.t(),
          :from_id => String.t(),
          :initiator_amount_final => integer(),
          :responder_amount_final => integer(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelSettleTxJson do
  def decode(value, _options) do
    value
  end
end
