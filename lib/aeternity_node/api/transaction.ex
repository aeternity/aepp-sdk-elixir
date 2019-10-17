defmodule AeternityNode.Api.Transaction do
  @moduledoc """
  API calls for all endpoints tagged `Transaction`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get pending transactions

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.GenericTxs{}} on success
  {:error, info} on failure
  """
  @spec get_pending_transactions(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.GenericTxs.t()} | {:error, Tesla.Env.t()}
  def get_pending_transactions(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/transactions/pending")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.GenericTxs{}}
    ])
  end

  @doc """
  Get a transaction by hash

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.GenericSignedTx{}} on success
  {:error, info} on failure
  """
  @spec get_transaction_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.GenericSignedTx.t()} | {:error, Tesla.Env.t()}
  def get_transaction_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/transactions/#{hash}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.GenericSignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - hash (String.t): The hash of the transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.TxInfoObject{}} on success
  {:error, info} on failure
  """
  @spec get_transaction_info_by_hash(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.TxInfoObject.t()} | {:error, Tesla.Env.t()}
  def get_transaction_info_by_hash(connection, hash, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/transactions/#{hash}/info")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.TxInfoObject{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a spend transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (SpendTx): A spend transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_spend(Tesla.Env.client(), AeternityNode.Model.SpendTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_spend(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/transactions/spend")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Post a new transaction

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (Tx): The new transaction
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.PostTxResponse{}} on success
  {:error, info} on failure
  """
  @spec post_transaction(Tesla.Env.client(), AeternityNode.Model.Tx.t(), keyword()) ::
          {:ok, AeternityNode.Model.PostTxResponse.t()} | {:error, Tesla.Env.t()}
  def post_transaction(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/transactions")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.PostTxResponse{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end
end
