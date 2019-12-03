defmodule AeternityNode.Api.Internal do
  @moduledoc """
  API calls for all endpoints tagged `Internal`.
  """

  alias AeternityNode.Connection
  import AeternityNode.RequestBuilder

  @doc """
  Dry-run transactions on top of a given block. Supports SpendTx, ContractCreateTx and ContractCallTx

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (DryRunInput): transactions
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.DryRunResults{}} on success
  {:error, info} on failure
  """
  @spec dry_run_txs(Tesla.Env.client(), AeternityNode.Model.DryRunInput.t(), keyword()) ::
          {:ok, AeternityNode.Model.DryRunResults.t()} | {:error, Tesla.Env.t()}
  def dry_run_txs(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/transactions/dry-run")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.DryRunResults{}},
      {403, %AeternityNode.Model.Error{}}
    ])
  end

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
  Get total token supply at height

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - height (integer()): The height
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.TokenSupply{}} on success
  {:error, info} on failure
  """
  @spec get_token_supply_by_height(Tesla.Env.client(), integer(), keyword()) ::
          {:ok, AeternityNode.Model.TokenSupply.t()} | {:error, Tesla.Env.t()}
  def get_token_supply_by_height(connection, height, _opts \\ []) do
    %{}
    |> method(:get)
    |> url("/debug/token-supply/height/#{height}")
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.TokenSupply{}},
      {400, %AeternityNode.Model.Error{}}
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

  @doc """
  Get a contract_call transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCallTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.UnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_contract_call(Tesla.Env.client(), AeternityNode.Model.ContractCallTx.t(), keyword()) ::
          {:ok, AeternityNode.Model.UnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_contract_call(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/call")
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
  Get a contract_create transaction object

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (ContractCreateTx): 
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %AeternityNode.Model.CreateContractUnsignedTx{}} on success
  {:error, info} on failure
  """
  @spec post_contract_create(
          Tesla.Env.client(),
          AeternityNode.Model.ContractCreateTx.t(),
          keyword()
        ) :: {:ok, AeternityNode.Model.CreateContractUnsignedTx.t()} | {:error, Tesla.Env.t()}
  def post_contract_create(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/debug/contracts/create")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, %AeternityNode.Model.CreateContractUnsignedTx{}},
      {400, %AeternityNode.Model.Error{}},
      {404, %AeternityNode.Model.Error{}}
    ])
  end

  @doc """
  Post a mined key block

  ## Parameters

  - connection (AeternityNode.Connection): Connection to server
  - body (KeyBlock): Mined key block
  - opts (KeywordList): [optional] Optional parameters
  ## Returns

  {:ok, %{}} on success
  {:error, info} on failure
  """
  @spec post_key_block(Tesla.Env.client(), AeternityNode.Model.KeyBlock.t(), keyword()) ::
          {:ok, nil} | {:error, Tesla.Env.t()}
  def post_key_block(connection, body, _opts \\ []) do
    %{}
    |> method(:post)
    |> url("/key-blocks")
    |> add_param(:body, :body, body)
    |> Enum.into([])
    |> (&Connection.request(connection, &1)).()
    |> evaluate_response([
      {200, false},
      {400, %AeternityNode.Model.Error{}}
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
end
