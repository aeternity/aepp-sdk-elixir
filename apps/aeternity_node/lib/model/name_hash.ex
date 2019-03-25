defmodule AeternityNode.Model.NameHash do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :name_id
  ]

  @type t :: %__MODULE__{
          :name_id => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.NameHash do
  def decode(value, _options) do
    value
  end
end
