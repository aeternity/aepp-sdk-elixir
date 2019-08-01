defmodule AeternityNode.Model.RelativeTtl do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :type,
    :value
  ]

  @type t :: %__MODULE__{
          :type => String.t(),
          :value => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.RelativeTtl do
  def decode(value, _options) do
    value
  end
end
