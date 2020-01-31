defmodule AeternityNode.Model.ChannelForceProgressTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :channel_id,
    :from_id,
    :payload,
    :round,
    :update,
    :state_hash,
    :ttl,
    :fee,
    :nonce,
    :offchain_trees
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :channel_id => String.t(),
          :from_id => String.t(),
          :payload => String.t(),
          :round => integer(),
          :update => OffChainUpdate,
          :state_hash => String.t(),
          :ttl => integer() | nil,
          :fee => integer(),
          :nonce => integer() | nil,
          :offchain_trees => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ChannelForceProgressTxJson do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:update, :struct, AeternityNode.Model.OffChainUpdate, options)
  end
end
