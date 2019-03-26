defmodule AeternityNode.Model.ContractCallObject do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :caller_id,
    :caller_nonce,
    :height,
    :contract_id,
    :gas_price,
    :gas_used,
    :log,
    :return_value,
    :return_type
  ]

  @type t :: %__MODULE__{
          :caller_id => String.t(),
          :caller_nonce => integer(),
          :height => integer(),
          :contract_id => String.t(),
          :gas_price => integer(),
          :gas_used => integer(),
          :log => [Event],
          :return_value => String.t(),
          :return_type => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.ContractCallObject do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:log, :list, AeternityNode.Model.Event, options)
  end
end
