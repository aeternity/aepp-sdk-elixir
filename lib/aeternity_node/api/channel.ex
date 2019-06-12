defmodule AeternityNode.Api.Channel do
  @moduledoc """
  API calls for all endpoints tagged `Channel`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Get channel by public key

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - pubkey (String.t): The pubkey of the channel
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.Channel{}} on success
  {:error, info} on failure
  """
  @spec get_channel_by_pubkey(Tesla.Env.client(), String.t(), keyword()) ::
          {:ok, AeternityNode.Model.Channel.t()} | {:error, Tesla.Env.t()}
  def get_channel_by_pubkey(connection, pubkey, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/channels/#{pubkey}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.Channel{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_close_mutual transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelCloseMutualTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_close_mutual(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelCloseMutualTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_close_mutual(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/close/mutual")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_close_solo transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelCloseSoloTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_close_solo(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelCloseSoloTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_close_solo(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/close/solo")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_create transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelCreateTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_create(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelCreateTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_create(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/create")
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
  Get a channel_deposit transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelDepositTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_deposit(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelDepositTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_deposit(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/deposit")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_settle transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelSettleTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_settle(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelSettleTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_settle(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/settle")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_slash transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelSlashTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_slash(Tesla.Env.client(), AeternityNode.Model.ChannelSlashTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_slash(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/slash")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_snapshot_solo transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelSnapshotSoloTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_snapshot_solo(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelSnapshotSoloTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_snapshot_solo(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/snapshot/solo")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Get a channel_withdrawal transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ChannelWithdrawTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_channel_withdraw(
          Tesla.Env.client(),
          AeternityNode.Model.ChannelWithdrawTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_channel_withdraw(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/channels/withdraw")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.UnsignedTx{}},
      {400, %AeternityNode.Model.Error{}}
    ])
  end
end
