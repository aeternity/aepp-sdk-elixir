defmodule AeternityNode.Model.ContractCallCompute do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :caller_id,
    :nonce,
    :contract_id,
    :vm_version,
    :abi_version,
    :fee,
    :ttl,
    :amount,
    :gas,
    :gas_price,
    :function,
    :arguments,
    :call
  ]

  @type t :: %__MODULE__{
          :caller_id => String.t(),
          :nonce => integer() | nil,
          :contract_id => String.t(),
          :vm_version => integer() | nil,
          :abi_version => integer() | nil,
          :fee => integer(),
          :ttl => integer() | nil,
          :amount => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :function => String.t() | nil,
          :arguments => String.t() | nil,
          :call => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractCallCompute do
  def decode(value, _options) do
    value
  end
end
