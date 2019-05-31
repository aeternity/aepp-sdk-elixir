defmodule Core.Channel do
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
    ChannelWithdrawTx,
    Error
  }

  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.Transaction

  @prefix_byte_size 2

  @spec get_by_pubkey(Core.Client.t(), binary()) ::
          {:error, Tesla.Env.t()} | {:ok, AeternityNode.Model.Channel.t()}
  def get_by_pubkey(%Client{connection: connection}, channel_pubkey) do
    prepare_result(ChannelAPI.get_channel_by_pubkey(connection, channel_pubkey))
  end

  def create(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        initiator_id,
        initiator_amount,
        responder_id,
        responder_amount,
        push_amount,
        channel_reserve,
        lock_period,
        state_hash,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, create_channel_tx} <-
           build_create_channel_tx(
             initiator_id,
             initiator_amount,
             responder_id,
             responder_amount,
             push_amount,
             channel_reserve,
             lock_period,
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :fee, 0),
             nonce,
             state_hash
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             create_channel_tx,
             height
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of ChannelCreateTx : #{inspect(error)}"}
    end
  end

  def close_mutual_tx(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        channel_id,
        from_id,
        initiator_amount_final,
        responder_amount_final,
        opts \\ []
      ) do
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
             connection,
             secret_key,
             network_id,
             gas_price,
             close_mutual_tx,
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelCloseMutualTx : #{inspect(error)}"}
    end
  end

  def close_solo_tx(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        channel_id,
        from_id,
        payload,
        poi,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, close_solo_tx} <-
           build_close_solo_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             from_id,
             nonce,
             payload,
             poi,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             close_solo_tx,
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelCloseSoloTx : #{inspect(error)}"}
    end
  end

  def deposit_tx(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        amount,
        channel_id,
        from_id,
        round,
        state_hash,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, deposit_tx} <-
           build_deposit_tx(
             amount,
             channel_id,
             Keyword.get(opts, :fee, 0),
             from_id,
             nonce,
             round,
             state_hash,
             Keyword.get(opts, :ttl, 0)
           ),
         {:ok, _} = response <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             deposit_tx,
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelDepositTx : #{inspect(error)}"}
    end
  end

  def force_progress_tx(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        channel_id,
        from_id,
        offchain_trees,
        payload,
        round,
        state_hash,
        update,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, force_progress_tx} <-
           build_force_progress_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             from_id,
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
             connection,
             secret_key,
             network_id,
             gas_price,
             force_progress_tx,
             height
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelForceProgressTx : #{inspect(error)}"}
    end
  end

  def settle_tx() do
    :ok
  end

  def slash_tx() do
    :ok
  end

  def snapshot_solo_tx() do
    :ok
  end

  def withdraw_tx() do
    :ok
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
       state_hash: state_hash
     }}
  end

  def build_close_mutual_tx(
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

  def build_deposit_tx(
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

  def build_force_progress_tx(
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
