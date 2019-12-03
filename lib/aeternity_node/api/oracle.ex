defmodule AeternityNode.Api.Oracle do
  @moduledoc """
  API calls for all endpoints tagged `Oracle`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get an oracle by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the oracle
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.RegisteredOracle{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.RegisteredOracle.t()} | {:error, Tesla.Env.t()}
  def get_oracle_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/oracles/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.RegisteredOracle{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get oracle queries by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the oracle
  - opts (KeywordList): [optional] Optional parameters
    - :from (String.t): Last query id in previous page
    - :limit (integer()): Max number of oracle queries
    - :type (String.t): The type of a query: open, closed or all
  ## Returns

  {:ok, %AeternityNode.Model.OracleQueries{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_queries_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.OracleQueries.t()} | {:error, Tesla.Env.t()}
  def get_oracle_queries_by_pubkey(connection, pubkey, opts \\ []) do
    optional_params = %{
      :from => :query,
      :limit => :query,
      :type => :query
    }

    %{}
    |> method(:get)
    |> url("/oracles/#{pubkey}/queries")
    |> add_optional_params(optional_params, opts)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.OracleQueries{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get an oracle query by public key and query ID

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The public key of the oracle
  - query_id (String.t): The ID of the query
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.OracleQuery{}} on success
  {:error, info} on failure
  """
  @spec get_oracle_query_by_pubkey_and_query_id(
          Tesla.Env.client(),
          String.t(),
          String.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.OracleQuery.t()} | {:error, Tesla.Env.t()}
  def get_oracle_query_by_pubkey_and_query_id(connection, pubkey, query_id, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/oracles/#{pubkey}/queries/#{query_id}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.OracleQuery{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get an oracle_extend transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (OracleExtendTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_oracle_extend(Tesla.Env.client(), AeternityNode.Model.OracleExtendTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_oracle_extend(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/oracles/extend")
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
  Get an oracle_query transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (OracleQueryTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_oracle_query(Tesla.Env.client(), AeternityNode.Model.OracleQueryTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_oracle_query(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/oracles/query")
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
  Get a oracle_register transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (OracleRegisterTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_oracle_register(
          Tesla.Env.client(),
          AeternityNode.Model.OracleRegisterTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_oracle_register(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/oracles/register")
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
  Get an oracle_response transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (OracleRespondTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_oracle_respond(
          Tesla.Env.client(),
          AeternityNode.Model.OracleRespondTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_oracle_respond(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/oracles/respond")
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
