defmodule AeternityNode.Model.ContractObject do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :owner_id,
    :vm_version,
    :abi_version,
    :active,
    :referrer_ids,
    :deposit
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :owner_id => String.t(),
          :vm_version => integer(),
          :abi_version => integer(),
          :active => boolean(),
          :referrer_ids => [String],
          :deposit => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractObject do
  def decode(value, _options) do
    value
  end
end
