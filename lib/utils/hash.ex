defmodule AeppSDK.Utils.Hash do
  @moduledoc """
  Contains hash-related functions.
  """
  @hash_bytes 32
  @type hash :: binary()

  @doc """
  Calculate the BLAKE2b hash of a binary.
  """
  @spec hash(binary()) :: {:ok, hash()} | {:error, atom()}
  def hash(payload) when is_binary(payload), do: :enacl.generichash(@hash_bytes, payload)
end
