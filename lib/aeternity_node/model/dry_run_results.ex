defmodule AeternityNode.Model.DryRunResults do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :results
  ]

  @type t :: %__MODULE__{
          :results => [DryRunResult]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunResults do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:results, :list, AeternityNode.Model.DryRunResult, options)
  end
end
