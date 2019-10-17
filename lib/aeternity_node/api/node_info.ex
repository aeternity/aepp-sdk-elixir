defmodule AeternityNode.Api.NodeInfo do
  @moduledoc """
  API calls for all endpoints tagged `NodeInfo`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get node's beneficiary public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.PubKey{}} on success
  {:error, info} on failure
  """
  @spec get_node_beneficiary(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.PubKey.t()} | {:error, Tesla.Env.t()}
  def get_node_beneficiary(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/accounts/beneficiary")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.PubKey{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get node's public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.PubKey{}} on success
  {:error, info} on failure
  """
  @spec get_node_pubkey(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.PubKey.t()} | {:error, Tesla.Env.t()}
  def get_node_pubkey(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/accounts/node")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.PubKey{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get peer public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.PeerPubKey{}} on success
  {:error, info} on failure
  """
  @spec get_peer_pubkey(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.PeerPubKey.t()} | {:error, Tesla.Env.t()}
  def get_peer_pubkey(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/peers/pubkey")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.PeerPubKey{}}
    ])
  end

  @doc """
  Get node Peers

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Peers{}} on success
  {:error, info} on failure
  """
  @spec get_peers(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.Peers.t()} | {:error, Tesla.Env.t()}
  def get_peers(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/peers")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Peers{}},
      {403, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get the status of a node

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Status{}} on success
  {:error, info} on failure
  """
  @spec get_status(Tesla.Env.client(), keyword()) ::
          {:ok, AeternityNode.Model.Status.t()} | {:error, Tesla.Env.t()}
  def get_status(connection, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/status")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Status{}}
    ])
  end
end
