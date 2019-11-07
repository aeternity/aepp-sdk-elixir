defmodule AeternityNode.Model.DryRunAccount do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :pub_key,
    :amount
  ]

  @type t :: %__MODULE__{
          :pub_key => String.t(),
          :amount => integer()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunAccount do
  def decode(value, _options) do
    value
  end
end
