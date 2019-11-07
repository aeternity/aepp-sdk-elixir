defmodule AeternityNode.Model.NameEntry do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :ttl,
    :pointers
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :ttl => integer(),
          :pointers => [NamePointer]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameEntry do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:pointers, :list, AeternityNode.Model.NamePointer, options)
  end
end
