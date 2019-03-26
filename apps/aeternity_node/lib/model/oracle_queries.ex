defmodule AeternityNode.Model.OracleQueries do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :oracle_queries
  ]

  @type t :: %__MODULE__{
          :oracle_queries => [OracleQuery]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.OracleQueries do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:oracle_queries, :list, AeternityNode.Model.OracleQuery, options)
  end
end
