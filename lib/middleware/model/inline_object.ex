defmodule Aeternal.Model.InlineObject do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :contract_id,
    :source,
    :compiler
  ]

  @type t :: %__MODULE__{
          :contract_id => String.t(),
          :source => String.t(),
          :compiler => String.t()
        }
end

defimpl Poison.Decoder, for: Aeternal.Model.InlineObject do
  def decode(value, _options) do
    value
  end
end
