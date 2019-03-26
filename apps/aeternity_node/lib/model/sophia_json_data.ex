defmodule AeternityNode.Model.SophiaJsonData do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :data
  ]

  @type t :: %__MODULE__{
          :data => Map
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.SophiaJsonData do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:data, :struct, AeternityNode.Model.Map, options)
  end
end
