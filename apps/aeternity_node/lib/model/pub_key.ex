defmodule AeternityNode.Model.PubKey do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :pub_key
  ]

  @type t :: %__MODULE__{
          :pub_key => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.PubKey do
  def decode(value, _options) do
    value
  end
end
