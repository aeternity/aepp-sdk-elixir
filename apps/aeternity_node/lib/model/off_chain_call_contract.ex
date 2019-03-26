defmodule AeternityNode.Model.OffChainCallContract do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :op,
    :caller,
    :contract,
    :vm_version,
    :abi_version,
    :amount,
    :gas,
    :gas_price,
    :call_data
  ]

  @type t :: %__MODULE__{
          :op => String.t(),
          :caller => String.t(),
          :contract => String.t(),
          :vm_version => integer() | nil,
          :abi_version => integer() | nil,
          :amount => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :call_data => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainCallContract do
  def decode(value, _options) do
    value
  end
end
