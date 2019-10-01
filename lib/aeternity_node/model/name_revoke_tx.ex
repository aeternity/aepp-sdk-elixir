defmodule AeternityNode.Model.NameRevokeTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :name_id,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :name_id => String.t(),
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameRevokeTx do
  def decode(value, _options) do
    value
  end
end
