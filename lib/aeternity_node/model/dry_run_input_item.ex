defmodule AeternityNode.Model.DryRunInputItem do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :tx,
    :call_req
  ]

  @type t :: %__MODULE__{
          :tx => String.t() | nil,
          :call_req => DryRunCallReq | nil
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.DryRunInputItem do
  import AeternityNode.Deserializer

  def decode(value, options) do
    value
    |> deserialize(:call_req, :struct, AeternityNode.Model.DryRunCallReq, options)
  end
end
