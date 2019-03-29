defmodule Utils.Serialization do
  @version_spend_tx 1

  @tag_spend_tx 12

  def serialize(fields, :spend_tx) do
    template = serialization_template(:spend_tx)
    fields_with_keys = set_keys(fields, template, [])
    :aeserialization.serialize(@tag_spend_tx, @version_spend_tx, template, fields_with_keys)
  end

  defp set_keys([field | rest_fields], [{key, _type} | rest_template], fields_with_keys),
    do: set_keys(rest_fields, rest_template, [{key, field} | fields_with_keys])

  defp set_keys([], [], fields_with_keys), do: Enum.reverse(fields_with_keys)

  defp serialization_template(:spend_tx) do
    [
      sender_id: :id,
      recipient_id: :id,
      amount: :int,
      fee: :int,
      ttl: :int,
      nonce: :int,
      payload: :binary
    ]
  end
end
