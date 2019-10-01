defmodule AeternityNode.Model.RegisteredOracle do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :query_format,
    :response_format,
    :query_fee,
    :ttl,
    :abi_version
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :query_format => String.t(),
          :response_format => String.t(),
          :query_fee => integer(),
          :ttl => integer(),
          :abi_version => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.RegisteredOracle do
  def decode(value, _options) do
    value
  end
end
