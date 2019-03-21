defmodule AeternityNode.Model.Channel do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :initiator_id,
    :responder_id,
    :channel_amount,
    :initiator_amount,
    :responder_amount,
    :channel_reserve,
    :delegate_ids,
    :state_hash,
    :round,
    :solo_round,
    :lock_period,
    :locked_until
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :initiator_id => String.t(),
          :responder_id => String.t(),
          :channel_amount => integer(),
          :initiator_amount => integer(),
          :responder_amount => integer(),
          :channel_reserve => integer(),
          :delegate_ids => [String],
          :state_hash => String.t(),
          :round => integer(),
          :solo_round => integer(),
          :lock_period => integer(),
          :locked_until => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Channel do
  def decode(value, _options) do
    value
  end
end
