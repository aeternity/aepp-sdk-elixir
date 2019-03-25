defmodule AeternityNode.Model.Protocol do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :effective_at_height
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :effective_at_height => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Protocol do
  def decode(value, _options) do
    value
  end
end
