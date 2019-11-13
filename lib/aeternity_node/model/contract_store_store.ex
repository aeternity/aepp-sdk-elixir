defmodule AeternityNode.Model.ContractStoreStore do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :key,
    :value
  ]

  @type t :: %__MODULE__{
          :key => String.t() | nil,
          :value => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractStoreStore do
  def decode(value, _options) do
    value
  end
end
