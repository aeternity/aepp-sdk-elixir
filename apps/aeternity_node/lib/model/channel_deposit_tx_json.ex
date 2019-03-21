defmodule AeternityNode.Model.ChannelDepositTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :channel_id,
    :from_id,
    :amount,
    :ttl,
    :fee,
    :nonce,
    :state_hash,
    :round
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :channel_id => String.t(),
          :from_id => String.t(),
          :amount => integer(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer(),
          :state_hash => String.t(),
          :round => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelDepositTxJson do
  def decode(value, _options) do
    value
  end
end
