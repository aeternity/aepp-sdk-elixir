defmodule AeternityNode.Model.ChannelCreateTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :initiator_id,
    :initiator_amount,
    :responder_id,
    :responder_amount,
    :push_amount,
    :channel_reserve,
    :lock_period,
    :ttl,
    :fee,
    :nonce,
    :state_hash
  ]

  @type t :: %__MODULE__{
          :initiator_id => String.t(),
          :initiator_amount => integer(),
          :responder_id => String.t(),
          :responder_amount => integer(),
          :push_amount => integer(),
          :channel_reserve => integer(),
          :lock_period => integer(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer() | nil,
          :state_hash => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelCreateTx do
  def decode(value, _options) do
    value
  end
end
