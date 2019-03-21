defmodule AeternityNode.Model.KeyBlock do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :hash,
    :height,
    :prev_hash,
    :prev_key_hash,
    :state_hash,
    :miner,
    :beneficiary,
    :target,
    :pow,
    :nonce,
    :time,
    :version,
    :info
  ]

  @type t :: %__MODULE__{
          :hash => String.t(),
          :height => integer(),
          :prev_hash => String.t(),
          :prev_key_hash => String.t(),
          :state_hash => String.t(),
          :miner => String.t(),
          :beneficiary => String.t(),
          :target => integer(),
          :pow => [integer()] | nil,
          :nonce => integer() | nil,
          :time => integer(),
          :version => integer(),
          :info => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.KeyBlock do
  def decode(value, _options) do
    value
  end
end
