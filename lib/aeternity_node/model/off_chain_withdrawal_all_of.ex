defmodule AeternityNode.Model.OffChainWithdrawalAllOf do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :to,
    :amount
  ]

  @type t :: %__MODULE__{
          :to => String.t(),
          :amount => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OffChainWithdrawalAllOf do
  def decode(value, _options) do
    value
  end
end
