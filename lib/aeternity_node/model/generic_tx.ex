defmodule AeternityNode.Model.GenericTx do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :version,
    :type
  ]

  @type t :: %__MODULE__{
          :version => integer(),
          :type => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.GenericTx do
  def decode(value, _options) do
    value
  end
end
