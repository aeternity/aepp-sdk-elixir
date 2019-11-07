defmodule AeternityNode.Model.DryRunResult do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :type,
    :result,
    :reason,
    :call_obj
  ]

  @type t :: %__MODULE__{
          :type => String.t(),
          :result => String.t(),
          :reason => String.t() | nil,
          :call_obj => ContractCallObject | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunResult do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:call_obj, :struct, AeternityNode.Model.ContractCallObject, options)
  end
end
