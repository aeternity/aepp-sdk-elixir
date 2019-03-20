defmodule Utils.Encoding do

  @spec binary_to_base58c(binary(), binary()) :: binary()
  def binary_to_base58c(prefix, payload) when is_binary(payload) do
    prefix <> "_" <> encode58(payload)
  end

  @spec base58c_to_binary(binary()) :: binary()
  def base58c_to_binary(<<_prefix::24, payload::binary>>) do
    decoded_payload =
      payload
      |> String.to_charlist()
      |> :base58.base58_to_binary()

    bsize = byte_size(decoded_payload) - 4
    <<data::binary-size(bsize), _checksum::binary-size(4)>> = decoded_payload

    data
  end

  defp encode58(payload) do
    checksum = generate_checksum(payload)

    payload
    |> Kernel.<>(checksum)
    |> :base58.binary_to_base58()
    |> to_string()
  end

  defp generate_checksum(payload) do
    <<checksum::binary-size(4), _::binary>> =
      :crypto.hash(:sha256, :crypto.hash(:sha256, payload))

    checksum
  end

end
