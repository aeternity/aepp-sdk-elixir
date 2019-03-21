defmodule AeternityNode.Model.OracleRegisterTxJson do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type,
    :query_format,
    :response_format,
    :query_fee,
    :oracle_ttl,
    :account_id,
    :nonce,
    :fee,
    :ttl,
    :vm_version,
    :abi_version
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t(),
          :query_format => String.t(),
          :response_format => String.t(),
          :query_fee => integer(),
          :oracle_ttl => Ttl,
          :account_id => String.t(),
          :nonce => integer() | nil,
          :fee => integer(),
          :ttl => integer() | nil,
          :vm_version => integer() | nil,
          :abi_version => integer() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OracleRegisterTxJson do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:oracle_ttl, :struct, AeternityNode.Model.Ttl, options)
  end
end
