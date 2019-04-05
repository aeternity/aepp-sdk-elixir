defmodule Utils.Account do
  @moduledoc """
  false
  """

  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Model.{Account, Error}
  alias Tesla.Env

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
