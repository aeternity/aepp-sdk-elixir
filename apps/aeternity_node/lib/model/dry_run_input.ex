defmodule AeternityNode.Model.DryRunInput do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :top,
    :accounts,
    :txs
  ]

  @type t :: %__MODULE__{
          :top => String.t() | nil,
          :accounts => [DryRunAccount] | nil,
          :txs => [String]
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunInput do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:accounts, :list, AeternityNode.Model.DryRunAccount, options)
  end
end
