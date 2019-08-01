defmodule AeternityNode.Model.CreateContractUnsignedTxAllOf do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :contract_id
  ]

  @type t :: %__MODULE__{
          :contract_id => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.CreateContractUnsignedTxAllOf do
  def decode(value, _options) do
    value
  end
end
