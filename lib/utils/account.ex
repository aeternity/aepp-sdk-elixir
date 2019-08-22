defmodule AeppSDK.Utils.Account do
  @moduledoc """
  Account AeppSDK.Utils.
  """

  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Model.{Account, Error}
  alias Tesla.Env

  @doc """
  Get the next valid nonce for a public key

  ## Example
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> AeppSDK.Utils.Account.next_valid_nonce(connection, public_key)
      {:ok, 8544}
  """
  @spec next_valid_nonce(Tesla.Client.t(), String.t()) ::
          {:ok, integer()} | {:error, String.t()} | {:error, Env.t()}
  def next_valid_nonce(connection, public_key) do
    response = AccountApi.get_account_by_pubkey(connection, public_key)

    prepare_result(response)
  end

  @doc """
  Get the nonce after a block indicated by hash

  ## Example
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> block_hash = "kh_WPQzXtyDiwvUs54N1L88YsLPn51PERHF76bqcMhpT5vnrAEAT"
      iex> AeppSDK.Utils.Account.nonce_at_hash(connection, public_key, block_hash)
      {:ok, 8327}
  """
  @spec nonce_at_hash(Tesla.Client.t(), String.t(), String.t()) ::
          {:ok, integer()} | {:error, String.t()} | {:error, Env.t()}
  def nonce_at_hash(connection, public_key, block_hash) do
    response = AccountApi.get_account_by_pubkey_and_hash(connection, public_key, block_hash)

    prepare_result(response)
  end

  defp prepare_result({:ok, %Account{nonce: nonce, kind: "basic"}}) do
    {:ok, nonce + 1}
  end

  defp prepare_result({:ok, %Account{kind: "generalized"}}) do
    {:ok, 0}
  end

  defp prepare_result({:ok, %Error{reason: message}}) do
    {:error, message}
  end

  defp prepare_result({:error, _} = error) do
    error
  end
end
