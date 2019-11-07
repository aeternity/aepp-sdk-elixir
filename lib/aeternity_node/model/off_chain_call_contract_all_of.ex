defmodule AeternityNode.Model.OffChainCallContractAllOf do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :caller,
    :contract,
    :abi_version,
    :amount,
    :gas,
    :gas_price,
    :call_data
  ]

  @type t :: %__MODULE__{
          :caller => String.t(),
          :contract => String.t(),
          :abi_version => integer(),
          :amount => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :call_data => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainCallContractAllOf do
  def decode(value, _options) do
    value
  end
end
