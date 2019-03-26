defmodule AeternityNode.Model.OracleResponseTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :query_id,
    :response,
    :response_ttl,
    :fee,
    :ttl,
    :oracle_id,
    :nonce
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :query_id => String.t(),
          :response => String.t(),
          :response_ttl => RelativeTtl,
          :fee => integer(),
          :ttl => integer() | nil,
          :oracle_id => String.t(),
          :nonce => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OracleResponseTxJson do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:response_ttl, :struct, AeternityNode.Model.RelativeTtl, options)
  end
end
