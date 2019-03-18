defmodule AeternityNode.Api.NodeInfo do
  @moduledoc """
  API calls for all endpoints tagged `NodeInfo`.
  """

  import AeternityNode.RequestBuilder

  @doc """
  Get node&#39;s beneficiary public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_node_beneficiary(Tesla.Env.client(), keyword()) ::
          {:ok, map()} | {:error, Tesla.Env.t()}
  def get_node_beneficiary(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/accounts/beneficiary")
    |> process_request(connection)
  end

  @doc """
  Get node&#39;s public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_node_pubkey(Tesla.Env.client(), keyword()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_node_pubkey(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/accounts/node")
    |> process_request(connection)
  end

  @doc """
  Get peer public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_peer_pubkey(Tesla.Env.client(), keyword()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_peer_pubkey(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/peers/pubkey")
    |> process_request(connection)
  end

  @doc """
  Get node Peers

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_peers(Tesla.Env.client(), keyword()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_peers(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/peers")
    |> process_request(connection)
  end

  @doc """
  Get the status of a node

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters

  ## Returns

  {:ok, map()} on success
  {:error, info} on failure
  """
  @spec get_status(Tesla.Env.client(), keyword()) :: {:ok, map()} | {:error, Tesla.Env.t()}
  def get_status(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/status")
    |> process_request(connection)
  end
end
