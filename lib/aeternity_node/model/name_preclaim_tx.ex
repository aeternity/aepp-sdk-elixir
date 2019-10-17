defmodule AeternityNode.Model.NamePreclaimTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :commitment_id,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :commitment_id => String.t(),
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NamePreclaimTx do
  def decode(value, _options) do
    value
  end
end
