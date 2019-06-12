defmodule AeternityNode.Model.OracleRegisterTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :query_format,
    :response_format,
    :query_fee,
    :oracle_ttl,
    :account_id,
    :nonce,
    :fee,
    :ttl,
    :abi_version
  ]

  @type t :: %__MODULE__{
          :query_format => String.t(),
          :response_format => String.t(),
          :query_fee => integer(),
          :oracle_ttl => Ttl,
          :account_id => String.t(),
          :nonce => integer() | nil,
          :fee => integer(),
          :ttl => integer() | nil,
          :abi_version => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OracleRegisterTx do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:oracle_ttl, :struct, AeternityNode.Model.Ttl, options)
  end
end
