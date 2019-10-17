defmodule AeternityNode.Model.ChannelCreateTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
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
    :state_hash,
    :delegate_ids
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
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
          :state_hash => String.t(),
          :delegate_ids => [String] | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelCreateTxJson do
  def decode(value, _options) do
    value
  end
end
