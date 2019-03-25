defmodule AeternityNode.Model.ContractStoreStore do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :value,
    :key
  ]

  @type t :: %__MODULE__{
          :value => String.t() | nil,
          :key => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractStoreStore do
  def decode(value, _options) do
    value
  end
end
