defmodule AeternityNode.Model.PostTxResponse do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :tx_hash
  ]

  @type t :: %__MODULE__{
          :tx_hash => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.PostTxResponse do
  def decode(value, _options) do
    value
  end
end
