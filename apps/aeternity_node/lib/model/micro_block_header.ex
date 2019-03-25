defmodule AeternityNode.Model.MicroBlockHeader do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :hash,
    :height,
    :pof_hash,
    :prev_hash,
    :prev_key_hash,
    :state_hash,
    :txs_hash,
    :signature,
    :time,
    :version
  ]

  @type t :: %__MODULE__{
          :hash => String.t(),
          :height => integer(),
          :pof_hash => String.t(),
          :prev_hash => String.t(),
          :prev_key_hash => String.t(),
          :state_hash => String.t(),
          :txs_hash => String.t(),
          :signature => String.t(),
          :time => integer(),
          :version => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.MicroBlockHeader do
  def decode(value, _options) do
    value
  end
end
