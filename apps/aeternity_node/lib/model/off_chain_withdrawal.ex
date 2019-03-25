defmodule AeternityNode.Model.OffChainWithdrawal do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :op,
    :to,
    :am
  ]

  @type t :: %__MODULE__{
          :op => String.t(),
          :to => String.t(),
          :am => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainWithdrawal do
  def decode(value, _options) do
    value
  end
end
