defmodule AeternityNode.Model.GaAttachTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :owner_id,
    :nonce,
    :code,
    :vm_version,
    :abi_version,
    :gas,
    :gas_price,
    :fee,
    :ttl,
    :call_data,
    :auth_fun
  ]

  @type t :: %__MODULE__{
          :owner_id => String.t(),
          :nonce => integer() | nil,
          :code => String.t(),
          :vm_version => integer(),
          :abi_version => integer(),
          :gas => integer(),
          :gas_price => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :call_data => String.t(),
          :auth_fun => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.GaAttachTx do
  def decode(value, _options) do
    value
  end
end
