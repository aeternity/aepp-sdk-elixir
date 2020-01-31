defmodule AeternityNode.Model.DryRunCallReq do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :calldata,
    :contract,
    :amount,
    :gas,
    :caller,
    :nonce,
    :abi_version,
    :context
  ]

  @type t :: %__MODULE__{
          :calldata => String.t(),
          :contract => String.t(),
          :amount => integer() | nil,
          :gas => integer() | nil,
          :caller => String.t() | nil,
          :nonce => integer() | nil,
          :abi_version => integer() | nil,
          :context => DryRunCallContext | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunCallReq do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:context, :struct, AeternityNode.Model.DryRunCallContext, options)
  end
end
