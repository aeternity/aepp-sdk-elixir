defmodule AeternityNode.Model.Account do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :id,
    :balance,
    :nonce,
    :payable,
    :kind,
    :contract_id,
    :auth_fun
  ]

  @type t :: %__MODULE__{
          :id => String.t(),
          :balance => integer(),
          :nonce => integer(),
          :payable => boolean() | nil,
          :kind => String.t() | nil,
          :contract_id => String.t() | nil,
          :auth_fun => String.t() | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.Account do
  def decode(value, _options) do
    value
  end
end
