defmodule AeternityNode.Model.ChannelDepositTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
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

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelDepositTx do
  def decode(value, _options) do
    value
  end
end
