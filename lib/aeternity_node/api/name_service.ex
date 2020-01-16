defmodule AeternityNode.Api.NameService do
  @moduledoc """
  API calls for all endpoints tagged `NameService`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Compute commitment ID for a given salt and name

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - name (String.t): Name
  - salt (integer()): Salt
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.CommitmentId{}} on success
  {:error, info} on failure
  """
  @spec get_commitment_id(Tesla.Env.client(), String.t(), integer(), keyword()) ::
          {:ok, AeternityNode.Model.CommitmentId.t()} | {:error, Tesla.Env.t()}
  def get_commitment_id(connection, name, salt, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/names/commitment-id")
    |> add_param(:query, :name, name)
    |> add_param(:query, :salt, salt)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.CommitmentId{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get name entry from naming system

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - name (String.t): The name key of the name entry
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.NameEntry{}} on success
  {:error, info} on failure
  """
  @spec get_name_entry_by_name(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.NameEntry.t()} | {:error, Tesla.Env.t()}
  def get_name_entry_by_name(connection, name, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/names/#{name}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.NameEntry{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a name_claim transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (NameClaimTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_name_claim(Tesla.Env.client(), AeternityNode.Model.NameClaimTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_name_claim(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/names/claim")
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
  Get a name_preclaim transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (NamePreclaimTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_name_preclaim(Tesla.Env.client(), AeternityNode.Model.NamePreclaimTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_name_preclaim(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/names/preclaim")
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
  Get a name_revoke transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (NameRevokeTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_name_revoke(Tesla.Env.client(), AeternityNode.Model.NameRevokeTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_name_revoke(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/names/revoke")
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
  Get a name_transfer transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (NameTransferTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_name_transfer(Tesla.Env.client(), AeternityNode.Model.NameTransferTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_name_transfer(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/names/transfer")
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
  Get a name_update transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (NameUpdateTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_name_update(Tesla.Env.client(), AeternityNode.Model.NameUpdateTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_name_update(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/names/update")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end
end
