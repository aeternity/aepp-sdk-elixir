defmodule AeternityNode.Model.OffChainNewContract do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :op,
    :owner,
    :vm_version,
    :abi_version,
    :code,
    :deposit,
    :call_data
  ]

  @type t :: %__MODULE__{
          :op => String.t(),
          :owner => String.t(),
          :vm_version => integer(),
          :abi_version => integer() | nil,
          :code => ByteCode,
          :deposit => integer(),
          :call_data => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainNewContract do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:code, :struct, AeternityNode.Model.ByteCode, options)
  end
end
