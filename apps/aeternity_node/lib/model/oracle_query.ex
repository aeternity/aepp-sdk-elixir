defmodule AeternityNode.Model.OracleQuery do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :sender_id,
    :sender_nonce,
    :oracle_id,
    :query,
    :response,
    :ttl,
    :response_ttl,
    :fee
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :sender_id => String.t(),
          :sender_nonce => integer(),
          :oracle_id => String.t(),
          :query => String.t(),
          :response => String.t(),
          :ttl => integer(),
          :response_ttl => Ttl,
          :fee => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OracleQuery do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:response_ttl, :struct, AeternityNode.Model.Ttl, options)
  end
end
