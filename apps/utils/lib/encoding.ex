defmodule Utils.Encoding do
  @checksum_bytes 4

  @prefix_bits 24

  @type base58c :: String.t()

  @type base64 :: String.t()

  @type hex :: String.t()

  @spec binary_to_base58c(binary(), binary()) :: base58c()
  def binary_to_base58c(prefix, payload) when is_binary(payload),
    do: prefix <> "_" <> encode_base58c(payload)

  @spec base58c_to_binary(base58c()) :: binary()
  def base58c_to_binary(<<_prefix::@prefix_bits, payload::binary>>) do
    decoded_payload =
      payload
      |> String.to_charlist()
      |> :base58.base58_to_binary()

    bsize = byte_size(decoded_payload) - @checksum_bytes
    <<data::binary-size(bsize), _checksum::binary-size(@checksum_bytes)>> = decoded_payload

    data
  end

  defp encode_base58c(payload) do
    checksum = generate_checksum(payload)

    payload
    |> Kernel.<>(checksum)
    |> :base58.binary_to_base58()
    |> to_string()
  end

  defp generate_checksum(payload) do
    <<checksum::binary-size(@checksum_bytes), _::binary>> =
      :crypto.hash(:sha256, :crypto.hash(:sha256, payload))

    checksum
  end
end
