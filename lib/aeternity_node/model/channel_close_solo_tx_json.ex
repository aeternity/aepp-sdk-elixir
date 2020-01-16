defmodule AeternityNode.Model.ChannelCloseSoloTxJson do
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
    :nonce,
    :poi
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :channel_id => String.t(),
          :from_id => String.t(),
          :payload => String.t(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer() | nil,
          :poi => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelCloseSoloTxJson do
  def decode(value, _options) do
    value
  end
end
