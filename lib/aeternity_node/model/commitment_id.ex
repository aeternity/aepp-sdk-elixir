defmodule AeternityNode.Model.CommitmentId do
  @moduledoc """

  """

  @derive [Poison.Encoder]
  defstruct [
    :commitment_id
  ]

  @type t :: %__MODULE__{
          :commitment_id => String.t()
        }
end

defimpl Poison.Decoder, for: AeternityNode.Model.CommitmentId do
  def decode(value, _options) do
    value
  end
end
