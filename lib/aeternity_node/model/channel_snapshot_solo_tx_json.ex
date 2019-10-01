defmodule AeternityNode.Model.ChannelSnapshotSoloTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :channel_id,
    :from_id,
    :payload,
    :ttl,
    :fee,
    :nonce
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :channel_id => String.t(),
          :from_id => String.t(),
          :payload => String.t(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelSnapshotSoloTxJson do
  def decode(value, _options) do
    value
  end
end
