defmodule AeppSDK.Utils.Chain do
  @moduledoc """
  Chain AeppSDK.Utils.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """
  alias AeppSDK.Client
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Model.{Error, KeyBlock, KeyBlockOrMicroBlockHeader, MicroBlockHeader}

  @doc """
  Get the hash of the current top block

  ## Example
      iex> AeppSDK.Utils.Chain.get_top_block_hash(client)
      {:ok, "kh_7e74Hs2ThcNdjFD1i5XngUbzTHgmXn9jTaXSej1XKio7rkpgM"}
  """
  @spec get_top_block_hash(Client.t()) ::
          {:ok, String.t()} | {:error, String.t()} | {:error, Env.t()}
  def get_top_block_hash(%Client{connection: connection}) do
    case ChainApi.get_top_block(connection) do
      {:ok, %KeyBlockOrMicroBlockHeader{key_block: %KeyBlock{hash: hash}}} ->
        {:ok, hash}

      {:ok, %KeyBlockOrMicroBlockHeader{micro_block: %MicroBlockHeader{hash: hash}}} ->
        {:ok, hash}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, _} = error ->
        error
    end
  end
end
