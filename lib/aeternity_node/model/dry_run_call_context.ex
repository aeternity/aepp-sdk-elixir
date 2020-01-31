defmodule AeternityNode.Model.DryRunCallContext do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :tx_hash,
    :stateful
  ]

  @type t :: %__MODULE__{
          :tx_hash => String.t() | nil,
          :stateful => boolean() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunCallContext do
  def decode(value, _options) do
    value
  end
end
