defmodule AeternityNode.Model.ContractCreateTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :owner_id,
    :nonce,
    :code,
    :vm_version,
    :abi_version,
    :deposit,
    :amount,
    :gas,
    :gas_price,
    :fee,
    :ttl,
    :call_data
  ]

  @type t :: %__MODULE__{
          :owner_id => String.t(),
          :nonce => integer() | nil,
          :code => String.t(),
          :vm_version => integer(),
          :abi_version => integer(),
          :deposit => integer(),
          :amount => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :call_data => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractCreateTx do
  def decode(value, _options) do
    value
  end
end
