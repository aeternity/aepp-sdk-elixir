defmodule AeternityNode.Model.PeerPubKey do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :pubkey
  ]

  @type t :: %__MODULE__{
          :pubkey => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.PeerPubKey do
  def decode(value, _options) do
    value
  end
end
