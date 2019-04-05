defmodule Utils.Chain do
  @moduledoc """
  false
  """
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Model.{KeyBlockOrMicroBlockHeader, KeyBlock, MicroBlockHeader, Error}
  alias Core.Client

  @spec get_top_block_hash(Client.t()) ::
          {:ok, String.t()} | {:error, String.t()} | {:error, Env.t()}
  def get_top_block_hash(connection) do
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
