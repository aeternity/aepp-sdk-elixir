defmodule AeternityNode.Model.NameClaimTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :name,
    :name_salt,
    :name_fee,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :name => String.t(),
          :name_salt => integer(),
          :name_fee => integer() | nil,
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameClaimTx do
  def decode(value, _options) do
    value
  end
end
