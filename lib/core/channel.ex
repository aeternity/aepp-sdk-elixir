defmodule Core.Channel do
  @moduledoc """
  Module for Aeternity Channel System, see: [https://github.com/aeternity/protocol/blob/master/channels/README.md](https://github.com/aeternity/protocol/blob/master/channels/README.md)
  Contains all channel-related functionality

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `Core.Client.new/4`
  """
  alias AeternityNode.Api.Channel, as: ChannelAPI
  alias AeternityNode.Api.Chain

  alias AeternityNode.Model.{
    ChannelCreateTx,
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx
  }

  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.Transaction

  @prefix_byte_size 2
  @state_hash_byte_size 32

  defguard valid_prefixes(sender_pubkey_prefix, channel_prefix)
           when sender_pubkey_prefix == "ak" and channel_prefix == "ch"

  @spec get_by_pubkey(Core.Client.t(), binary()) ::
          {:error, Tesla.Env.t()} | {:ok, AeternityNode.Model.Channel.t()}
  def get_by_pubkey(%Client{connection: connection}, channel_pubkey) do
    prepare_result(ChannelAPI.get_channel_by_pubkey(connection, channel_pubkey))
  end

  @doc """
  Creates a channel.
  More information at [https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_create](https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_create)

  ## Examples
      iex>
  """
  @spec create(
          Client.t(),
          non_neg_integer(),
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          binary(),
          list()
        ) :: {:ok, keyword()} | {:error, String.t()}
  def create(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        initiator_amount,
        <<responder_prefix::binary-size(@prefix_byte_size), _::binary>> = responder_id,
        responder_amount,
        push_amount,
        channel_reserve,
        lock_period,
        state_hash,
        opts \\ []
      )
      when sender_prefix == "ak" and responder_prefix == "ak" and
             byte_size(state_hash) == @state_hash_byte_size do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, create_channel_tx} <-
           build_create_channel_tx(
             sender_pubkey,
             initiator_amount,
             responder_id,
             responder_amount,
             push_amount,
             channel_reserve,
             lock_period,
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :delegate_ids, []),
             nonce,
             state_hash
           ),
         {:ok, tx, encoded_signed_tx, signature} <-
           Transaction.sign_tx(create_channel_tx, client, Keyword.get(opts, :auth, :no_opts)) do
      {:ok, [tx: tx, encoded_signed_tx: encoded_signed_tx, signature: signature]}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of ChannelCreateTx : #{inspect(error)}"}
    end
  end

  @doc """
  Closes a channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_close_mutual

  ## Examples
      iex>
  """
  @spec close_mutual(Client.t(), binary(), binary(), non_neg_integer(), non_neg_integer(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def close_mutual(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        <<from_prefix::binary-size(@prefix_byte_size), _::binary>> = from_id,
        initiator_amount_final,
        responder_amount_final,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) and initiator_amount_final >= 0 and
             responder_amount_final <= 0 and from_prefix == "ak" do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, close_mutual_tx} <-
           build_close_mutual_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             from_id,
             initiator_amount_final,
             nonce,
             responder_amount_final,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             close_mutual_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelCloseMutualTx : #{inspect(error)}"}
    end
  end

  @doc """
  Closes a channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_close_solo

  ## Examples
      iex>
  """
  @spec close_solo(Client.t(), binary(), String.t(), list(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def close_solo(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        payload,
        poi,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, close_solo_tx} <-
           build_close_solo_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             nonce,
             payload,
             poi,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             close_solo_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelCloseSoloTx : #{inspect(error)}"}
    end
  end

  @doc """
  Deposits funds into a channel after creation
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_deposit

  ## Examples
      iex>
  """
  @spec deposit(Client.t(), non_neg_integer(), binary(), non_neg_integer(), binary(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def deposit(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        amount,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        round,
        state_hash,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) and
             byte_size(state_hash) == @state_hash_byte_size do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, deposit_tx} <-
           build_deposit_tx(
             amount,
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             nonce,
             round,
             state_hash,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             deposit_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelDepositTx : #{inspect(error)}"}
    end
  end

  @doc """
  Forcing progress is the mechanism to be used when a dispute arises between parties and
  one of them wants to use the blockchain as an arbiter.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#forcing-progress

  ## Examples
      iex>
  """
  @spec force_progress(
          Client.t(),
          binary(),
          list(binary()),
          String.t(),
          non_neg_integer(),
          binary(),
          binary(),
          list()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def force_progress(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        offchain_trees,
        payload,
        round,
        state_hash,
        update,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, force_progress_tx} <-
           build_force_progress_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             nonce,
             offchain_trees,
             payload,
             round,
             state_hash,
             Keyword.get(opts, :ttl, 0),
             update
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             force_progress_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelForceProgressTx : #{inspect(error)}"}
    end
  end

  @doc """
  The settlement transaction is the last one in the lifecycle of a channel,
  but only required if the parties involved did not manage to cooperate when
  trying to close the channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_settle

  ## Examples
      iex>
  """
  @spec settle(Client.t(), binary(), non_neg_integer(), non_neg_integer(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def settle(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        initiator_amount_final,
        responder_amount_final,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, settle_tx} <-
           build_settle_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             initiator_amount_final,
             nonce,
             responder_amount_final,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             settle_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelSettleTx : #{inspect(error)}"}
    end
  end

  @doc """
  If a malicious party sent a channel_close_solo or channel_force_progress_tx with an outdated state,
  the honest party has the opportunity to issue a channel_slash transaction
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_slash

  ## Examples
      iex>
  """
  @spec slash(Client.t(), binary(), String.t(), list(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def slash(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        payload,
        poi,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, slash_tx} <-
           build_slash_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             nonce,
             payload,
             poi,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             slash_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelSlashTx : #{inspect(error)}"}
    end
  end

  @doc """
  In order to make channels both secure and trustless even when one party goes offline,
  we provide the functionality of snapshots. Snapshots provide a recent off-chain state
  to be recorded on-chain.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_snapshot_solo

  ## Examples
      iex>
  """
  @spec snapshot_solo(Client.t(), binary(), String.t(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def snapshot_solo(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        payload,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, snapshot_solo_tx} <-
           build_snapshot_solo_tx(
             channel_id,
             sender_pubkey,
             payload,
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :fee, 0),
             nonce
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             snapshot_solo_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelSnapshotSoloTx : #{inspect(error)}"}
    end
  end

  @doc """
  Witdraws locked tokens from channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_withdraw

  ## Examples
      iex>
  """
  @spec withdraw(
          Client.t(),
          binary(),
          binary(),
          non_neg_integer(),
          binary(),
          non_neg_integer(),
          list()
        ) ::
          {:ok, map()} | {:error, String.t()}
  def withdraw(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        to_id,
        amount,
        state_hash,
        round,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) and
             byte_size(state_hash) == @state_hash_byte_size do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, withdraw_tx} <-
           build_withdraw_tx(
             channel_id,
             to_id,
             amount,
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :fee, 0),
             nonce,
             state_hash,
             round
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             client,
             withdraw_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelWithdrawTx : #{inspect(error)}"}
    end
  end

  defp build_create_channel_tx(
         initiator_id,
         initiator_amount,
         responder_id,
         responder_amount,
         push_amount,
         channel_reserve,
         lock_period,
         ttl,
         fee,
         delegate_ids,
         nonce,
         state_hash
       ) do
    {:ok,
     %ChannelCreateTx{
       initiator_id: initiator_id,
       initiator_amount: initiator_amount,
       responder_id: responder_id,
       responder_amount: responder_amount,
       push_amount: push_amount,
       channel_reserve: channel_reserve,
       lock_period: lock_period,
       ttl: ttl,
       fee: fee,
       nonce: nonce,
       delegate_ids: delegate_ids,
       state_hash: state_hash
     }}
  end

  defp build_close_mutual_tx(
         channel_id,
         fee,
         from_id,
         initiator_amount_final,
         nonce,
         responder_amount_final,
         ttl
       ) do
    {:ok,
     %ChannelCloseMutualTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       initiator_amount_final: initiator_amount_final,
       nonce: nonce,
       responder_amount_final: responder_amount_final,
       ttl: ttl
     }}
  end

  defp build_close_solo_tx(
         channel_id,
         fee,
         from_id,
         nonce,
         payload,
         poi,
         ttl
       ) do
    {:ok,
     %ChannelCloseSoloTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       nonce: nonce,
       payload: payload,
       poi: poi,
       ttl: ttl
     }}
  end

  defp build_deposit_tx(
         amount,
         channel_id,
         fee,
         from_id,
         nonce,
         round,
         state_hash,
         ttl
       ) do
    {:ok,
     %ChannelDepositTx{
       amount: amount,
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       nonce: nonce,
       round: round,
       state_hash: state_hash,
       ttl: ttl
     }}
  end

  defp build_force_progress_tx(
         channel_id,
         fee,
         from_id,
         nonce,
         offchain_trees,
         payload,
         round,
         state_hash,
         ttl,
         update
       ) do
    {:ok,
     %ChannelForceProgressTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       nonce: nonce,
       offchain_trees: offchain_trees,
       payload: payload,
       round: round,
       state_hash: state_hash,
       ttl: ttl,
       update: update
     }}
  end

  defp build_settle_tx(
         channel_id,
         fee,
         from_id,
         initiator_amount_final,
         nonce,
         responder_amount_final,
         ttl
       ) do
    {:ok,
     %ChannelSettleTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       initiator_amount_final: initiator_amount_final,
       nonce: nonce,
       responder_amount_final: responder_amount_final,
       ttl: ttl
     }}
  end

  defp build_slash_tx(
         channel_id,
         fee,
         from_id,
         nonce,
         payload,
         poi,
         ttl
       ) do
    {:ok,
     %ChannelSlashTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       nonce: nonce,
       payload: payload,
       poi: poi,
       ttl: ttl
     }}
  end

  defp build_snapshot_solo_tx(
         channel_id,
         from_id,
         payload,
         ttl,
         fee,
         nonce
       ) do
    {:ok,
     %ChannelSnapshotSoloTx{
       channel_id: channel_id,
       from_id: from_id,
       payload: payload,
       ttl: ttl,
       fee: fee,
       nonce: nonce
     }}
  end

  defp build_withdraw_tx(
         channel_id,
         to_id,
         amount,
         ttl,
         fee,
         nonce,
         state_hash,
         round
       ) do
    {:ok,
     %ChannelWithdrawTx{
       channel_id: channel_id,
       to_id: to_id,
       amount: amount,
       ttl: ttl,
       fee: fee,
       nonce: nonce,
       state_hash: state_hash,
       round: round
     }}
  end

  defp prepare_result({:ok, %Tesla.Env{} = env}) do
    {:error, env}
  end

  defp prepare_result({:ok, response}) do
    {:ok, response}
  end

  defp prepare_result({:error, _} = error) do
    error
  end
end
