defmodule Utils.Account do
  @moduledoc """
  Account utils
  """

  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Model.{Account, Error}
  alias Tesla.Env

  @doc """
  Get the next valid nonce for a public key

  ## Examples
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> Utils.Account.next_valid_nonce(connection, pubkey)
      {:ok, 8544}
  """
  @spec next_valid_nonce(Env.t(), String.t()) ::
          {:ok, integer()} | {:error, String.t()} | {:error, Env.t()}
  def next_valid_nonce(connection, pubkey) do
    case AccountApi.get_account_by_pubkey(connection, pubkey) do
      {:ok, %Account{nonce: nonce}} ->
        {:ok, nonce + 1}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}
    end
  end
end
