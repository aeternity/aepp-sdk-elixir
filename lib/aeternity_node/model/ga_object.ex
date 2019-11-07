defmodule AeternityNode.Model.GaObject do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :caller_id,
    :height,
    :gas_price,
    :gas_used,
    :return_value,
    :return_type,
    :inner_object
  ]

  @type t :: %__MODULE__{
          :caller_id => String.t(),
          :height => integer(),
          :gas_price => integer(),
          :gas_used => integer(),
          :return_value => String.t(),
          :return_type => String.t(),
          :inner_object => TxInfoObject | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.GaObject do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:inner_object, :struct, AeternityNode.Model.TxInfoObject, options)
  end
end
