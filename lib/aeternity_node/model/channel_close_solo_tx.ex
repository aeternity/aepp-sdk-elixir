defmodule AeternityNode.Model.ChannelCloseSoloTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :channel_id,
    :from_id,
    :payload,
    :ttl,
    :fee,
    :nonce,
    :poi
  ]

  @type t :: %__MODULE__{
          :channel_id => String.t(),
          :from_id => String.t(),
          :payload => String.t(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer() | nil,
          :poi => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelCloseSoloTx do
  def decode(value, _options) do
    value
  end
end
