defmodule AeternityNode.Model.PeerConnections do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :inbound,
    :outbound
  ]

  @type t :: %__MODULE__{
          :inbound => integer(),
          :outbound => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.PeerConnections do
  def decode(value, _options) do
    value
  end
end
