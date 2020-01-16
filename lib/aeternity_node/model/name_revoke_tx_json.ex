defmodule AeternityNode.Model.NameRevokeTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :name_id,
    :fee,
    :ttl,
    :account_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :name_id => String.t(),
          :fee => integer(),
          :ttl => integer() | nil,
          :account_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameRevokeTxJson do
  def decode(value, _options) do
    value
  end
end
