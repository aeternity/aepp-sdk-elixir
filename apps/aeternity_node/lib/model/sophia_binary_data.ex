defmodule AeternityNode.Model.SophiaBinaryData do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :"sophia-type",
    :data
  ]

  @type t :: %__MODULE__{
          :"sophia-type" => String.t(),
          :data => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.SophiaBinaryData do
  def decode(value, _options) do
    value
  end
end
