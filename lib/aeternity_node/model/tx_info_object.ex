defmodule AeternityNode.Model.TxInfoObject do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :call_info,
    :ga_info,
    :tx_info
  ]

  @type t :: %__MODULE__{
          :call_info => ContractCallObject | nil,
          :ga_info => GaObject | nil,
          :tx_info => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.TxInfoObject do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:call_info, :struct, AeternityNode.Model.ContractCallObject, options)
    |> deserialize(:ga_info, :struct, AeternityNode.Model.GaObject, options)
  end
end
