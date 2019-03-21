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
    :vm_version,
    :abi_version
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :query_format => String.t(),
          :response_format => String.t(),
          :query_fee => integer(),
          :ttl => integer(),
          :vm_version => integer() | nil,
          :abi_version => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.RegisteredOracle do
  def decode(value, _options) do
    value
  end
end
