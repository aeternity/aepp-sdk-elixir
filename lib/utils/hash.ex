defmodule AeppSDK.Utils.Hash do
  @moduledoc """
  Contains hash-related functions.
  """
  @hash_bytes 32
  @type hash :: binary()

  @doc """
  Calculate the BLAKE2b hash of a binary.

  ## Example
      iex> AeppSDK.Utils.Hash.hash(<<0::32>>)
      {:ok,
       <<17, 218, 109, 31, 118, 29, 223, 155, 219, 76, 157, 110, 83, 3, 235, 212, 31,
         97, 133, 141, 10, 86, 71, 161, 167, 191, 224, 137, 191, 146, 27, 233>>}
  """
  @spec hash(binary()) :: {:ok, hash()} | {:error, atom()}
  def hash(payload) when is_binary(payload), do: :enacl.generichash(@hash_bytes, payload)
end
