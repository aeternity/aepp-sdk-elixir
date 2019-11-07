defmodule AeternityNode.Model.Status do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :genesis_key_block_hash,
    :solutions,
    :difficulty,
    :syncing,
    :sync_progress,
    :listening,
    :protocols,
    :node_version,
    :node_revision,
    :peer_count,
    :pending_transactions_count,
    :network_id,
    :peer_pubkey,
    :top_key_block_hash,
    :top_block_height
  ]

  @type t :: %__MODULE__{
          :genesis_key_block_hash => String.t(),
          :solutions => integer(),
          :difficulty => integer(),
          :syncing => boolean(),
          :sync_progress => float() | nil,
          :listening => boolean(),
          :protocols => [Protocol],
          :node_version => String.t(),
          :node_revision => String.t(),
          :peer_count => integer(),
          :pending_transactions_count => integer(),
          :network_id => String.t(),
          :peer_pubkey => String.t(),
          :top_key_block_hash => String.t(),
          :top_block_height => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Status do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:protocols, :list, AeternityNode.Model.Protocol, options)
  end
end
