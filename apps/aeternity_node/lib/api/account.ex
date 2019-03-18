defmodule AeternityNode.Api.Account do
  @moduledoc """
  API calls for all endpoints tagged `Account`.
  """

  import AeternityNode.RequestBuilder

  @doc """
  Get an account by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_account_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_account_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}")
    |> process_request(connection)
  end

  @doc """
  Get an account by public key after the block indicated by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - hash (String.t): The hash of the block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_account_by_pubkey_and_hash(Tesla.Env.client(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_account_by_pubkey_and_hash(connection, pubkey, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}/hash/#{hash}")
    |> process_request(connection)
  end

  @doc """
  Get an account by public key after the opening key block of the generation at height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - height (integer()): The height of the key block
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_account_by_pubkey_and_height(Tesla.Env.client(), String.t(), integer(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_account_by_pubkey_and_height(connection, pubkey, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}/height/#{height}")
    |> process_request(connection)
  end

  @doc """
  Get pending account transactions by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the account
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_pending_account_transactions_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_pending_account_transactions_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/accounts/#{pubkey}/transactions/pending")
    |> process_request(connection)
  end
end
