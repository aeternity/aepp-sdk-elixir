defmodule AeternityNode.Model.OffChainUpdate do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :op
  ]

  @type t :: %__MODULE__{
          :op => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainUpdate do
  def decode(value, _options) do
    value
  end
end
