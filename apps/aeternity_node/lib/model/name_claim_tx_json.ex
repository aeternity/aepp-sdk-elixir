defmodule AeternityNode.Model.NameClaimTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :name,
    :name_salt,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :name => String.t(),
          :name_salt => integer(),
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameClaimTxJson do
  def decode(value, _options) do
    value
  end
end
