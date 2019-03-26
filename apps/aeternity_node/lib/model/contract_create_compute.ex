defmodule AeternityNode.Model.ContractCreateCompute do
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
    :arguments,
    :call
  ]

  @type t :: %__MODULE__{
          :owner_id => String.t(),
          :nonce => integer() | nil,
          :code => String.t(),
          :vm_version => integer(),
          :abi_version => integer() | nil,
          :deposit => integer(),
          :amount => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :arguments => String.t() | nil,
          :call => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractCreateCompute do
  def decode(value, _options) do
    value
  end
end
