defmodule Core.Channel do
  @moduledoc """
  Module for Aeternity Channel System, see: [https://github.com/aeternity/protocol/blob/master/channels/README.md](https://github.com/aeternity/protocol/blob/master/channels/README.md)
  Contains all channel-related functionality.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `Core.Client.new/4`.
  """
  alias AeternityNode.Api.Channel, as: ChannelAPI
  alias AeternityNode.Api.Chain
  alias Core.GeneralizedAccount

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
    Error,
    Channel
  }

  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.{Transaction, Encoding, Hash}

  @prefix_byte_size 2
  @state_hash_byte_size 32

  defguard valid_prefixes(sender_pubkey_prefix, channel_prefix)
           when sender_pubkey_prefix == "ak" and channel_prefix == "ch"

  @doc """
  Gets channel information by its pubkey.

  ## Example
      iex> Core.Channel.get_by_pubkey(client, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay")
      {:ok,
         %AeternityNode.Model.Channel{
           channel_amount: 16720002000,
           channel_reserve: 1000,
           delegate_ids: [],
           id: "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay",
           initiator_amount: 1000,
           initiator_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
           lock_period: 100,
           locked_until: 0,
           responder_amount: 1000,
           responder_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
           round: 2,
           solo_round: 0,
           state_hash: "st_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAArMtts"
         }}

  """
  @spec get_by_pubkey(Core.Client.t(), binary()) ::
          {:error, Tesla.Env.t()} | {:ok, AeternityNode.Model.Channel.t()}
  def get_by_pubkey(%Client{connection: connection}, channel_pubkey) do
    prepare_result(ChannelAPI.get_channel_by_pubkey(connection, channel_pubkey))
  end

  @doc """
  Creates a channel.
  More information at [https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_create](https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_create)

  ## Example
      iex> Core.Channel.create(client, 1000, client1.keypair.public ,1000, 1000, 1000, 100, "st_11111111111111111111111111111111273Yts")
      {:ok,
        [
          %AeternityNode.Model.ChannelCreateTx{
            channel_reserve: 1000,
            delegate_ids: [],
            fee: 17480000000,
            initiator_amount: 1000,
            initiator_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            lock_period: 100,
            nonce: 2,
            push_amount: 1000,
            responder_amount: 1000,
            responder_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
            state_hash:"st_11111111111111111111111111111111273Yts",
            ttl: 0
          },
          <<57, 30, 45, 155, 161, 147, 152, 117, 167, 202, 127, 50, 186, 142, 248, 183,
            245, 237, 11, 198, 95, 30, 247, 78, 16, 18, 109, 90, 182, 112, 241, 61, 92,
            97, 212, 128, 172, 40, 96, 81, 201, 207, 100, 15, 133, 174, 95, 140, 88, 96,
            253, 85, 93, 32, 78, 78, 61, 230, 29, 58, 14, 104, 157, 5>>
        ]}
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
        <<"st_", state_hash::binary>> = encoded_state_hash,
        opts \\ []
      )
      when sender_prefix == "ak" and responder_prefix == "ak" do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
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
             encoded_state_hash
           ),
         {:ok, %{height: height}} <-
           AeternityNode.Api.Chain.get_current_key_block_height(client.connection),
         fee <-
           Transaction.calculate_n_times_fee(
             create_channel_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{create_channel_tx | fee: fee},
             client,
             Keyword.get(opts, :auth, :no_opts)
           ) do
      res
    else
      false -> {:error, "#{__MODULE__}: Incorrect state hash size."}
      error -> {:error, "#{__MODULE__}: Unsuccessful post of ChannelCreateTx : #{inspect(error)}"}
    end
  end

  @doc """
  Closes a channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_close_mutual

  ## Example
      iex> Core.Channel.close_mutual(client, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay",2000,12000000)
      {:ok,
        [
          %AeternityNode.Model.ChannelCloseMutualTx{
            channel_id: "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay",
            fee: 16740000000,
            from_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            initiator_amount_final: 2000,
            nonce: 5,
            responder_amount_final: 12000000,
            ttl: 0
          },
          <<154, 198, 126, 220, 52, 91, 55, 178, 103, 155, 224, 160, 38, 97, 203, 251, 95,
            184, 237, 184, 100, 14, 142, 198, 103, 42, 119, 49, 90, 193, 111, 86, 233,
            167, 125, 207, 57, 66, 91, 211, 225, 192, 219, 245, 99, 50, 214, 2, 10, 130,
            165, 215, 161, 72, 62, 202, 98, 170, 134, 52, 200, 23, 85, 7>>
        ]}
  """
  @spec close_mutual(Client.t(), binary(), non_neg_integer(), non_neg_integer(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def close_mutual(
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
      when valid_prefixes(sender_prefix, channel_prefix) and initiator_amount_final >= 0 and
             responder_amount_final >= 0 do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, close_mutual_tx} <-
           build_close_mutual_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             initiator_amount_final,
             nonce,
             responder_amount_final,
             Keyword.get(opts, :ttl, 0)
           ),
         fee <-
           Transaction.calculate_n_times_fee(
             close_mutual_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{close_mutual_tx | fee: fee},
             client,
             Keyword.get(opts, :auth, :no_opts)
           ) do
      res
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelCloseMutualTx : #{inspect(error)}"}
    end
  end

  @doc """
  Closes a channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_close_solo
  """
  @spec close_solo(Client.t(), binary(), binary(), binary(), list()) ::
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
      when valid_prefixes(sender_prefix, channel_prefix) and is_binary(poi) and is_binary(payload) do
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
         fee <-
           Transaction.calculate_n_times_fee(
             close_solo_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _response} = response <-
           Transaction.try_post(
             client,
             %{close_solo_tx | fee: fee},
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

  ## Example
      iex> Core.Channel.deposit(client, 16720000000, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay", 2, Encoding.prefix_encode_base58c("st", <<0::256>>))
      {:ok,
        [
          %AeternityNode.Model.ChannelDepositTx{
            amount: 16720000000,
            channel_id: "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay",
            fee: 17400000000,
            from_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            nonce: 3,
            round: 2,
            state_hash: "st_11111111111111111111111111111111273Yts",
            ttl: 0
          },
          <<44, 241, 124, 7, 189, 254, 202, 235, 78, 79, 88, 185, 235, 90, 234, 213, 246,
            149, 239, 157, 69, 42, 234, 50, 68, 76, 194, 42, 21, 200, 29, 82, 134, 126,
            53, 228, 12, 77, 80, 150, 65, 211, 194, 127, 22, 93, 106, 254, 143, 15, 216,
            79, 56, 104, 96, 48, 45, 9, 137, 108, 15, 29, 121, 1>>
        ]}
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
        <<"st_", state_hash::binary>> = encoded_state_hash,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
         {:ok, deposit_tx} <-
           build_deposit_tx(
             amount,
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             nonce,
             round,
             encoded_state_hash,
             Keyword.get(opts, :ttl, 0)
           ),
         fee <-
           Transaction.calculate_n_times_fee(
             deposit_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{deposit_tx | fee: fee},
             client,
             Keyword.get(opts, :auth, :no_opts)
           ) do
      res
    else
      false ->
        {:error, "#{__MODULE__}: Incorrect state hash size."}

      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelDepositTx : #{inspect(error)}"}
    end
  end

  @doc """
  Forcing progress is the mechanism to be used when a dispute arises between parties and
  one of them wants to use the blockchain as an arbiter.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#forcing-progress
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
        <<"st_", state_hash::binary>> = encoded_state_hash,
        update,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
         {:ok, force_progress_tx} <-
           build_force_progress_tx(
             channel_id,
             Keyword.get(opts, :fee, 0),
             sender_pubkey,
             nonce,
             offchain_trees,
             payload,
             round,
             encoded_state_hash,
             Keyword.get(opts, :ttl, 0),
             update
           ),
         fee <-
           Transaction.calculate_n_times_fee(
             force_progress_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _response} = response <-
           Transaction.try_post(
             client,
             %{force_progress_tx | fee: fee},
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      false ->
        {:error, "#{__MODULE__}: Incorrect state hash size."}

      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelForceProgressTx : #{inspect(error)}"}
    end
  end

  @doc """
  The settlement transaction is the last one in the lifecycle of a channel,
  but only required if the parties involved did not manage to cooperate when
  trying to close the channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_settle
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
         fee <-
           Transaction.calculate_n_times_fee(
             settle_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _response} = response <-
           Transaction.try_post(
             client,
             %{settle_tx | fee: fee},
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
         fee <-
           Transaction.calculate_n_times_fee(
             slash_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _response} = response <-
           Transaction.try_post(
             client,
             %{slash_tx | fee: fee},
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
         fee <-
           Transaction.calculate_n_times_fee(
             snapshot_solo_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _response} = response <-
           Transaction.try_post(
             client,
             %{snapshot_solo_tx | fee: fee},
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

  ## Example
      iex> Core.Channel.withdraw(client, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay", "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU", 2000, Utils.Encoding.prefix_encode_base58c("st", <<0::256>>), 3)
      {:ok,
        [
          %AeternityNode.Model.ChannelWithdrawTx{
            amount: 2000,
            channel_id: "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay",
            fee: 17340000000,
            nonce: 3,
            round: 3,
            state_hash: "st_11111111111111111111111111111111273Yts",
            to_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            ttl: 0
          },
          <<125, 128, 179, 4, 157, 39, 210, 210, 55, 199, 175, 101, 22, 45, 219, 123, 131,
            88, 103, 91, 30, 140, 190, 109, 26, 212, 188, 82, 174, 253, 2, 148, 205, 112,
            94, 106, 218, 54, 250, 185, 144, 170, 227, 114, 36, 232, 24, 157, 164, 143,
            66, 47, 177, 190, 24, 69, 60, 65, 119, 133, 147, 191, 191, 8>>
        ]}
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
        <<"st_", state_hash::binary>> = encoded_state_hash,
        round,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
         {:ok, withdraw_tx} <-
           build_withdraw_tx(
             channel_id,
             to_id,
             amount,
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :fee, 0),
             nonce,
             encoded_state_hash,
             round
           ),
         fee <-
           Transaction.calculate_n_times_fee(
             withdraw_tx,
             height,
             client.network_id,
             0,
             client.gas_price,
             5
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{withdraw_tx | fee: fee},
             client,
             Keyword.get(opts, :auth, :no_opts)
           ) do
      res
    else
      false ->
        {:error, "#{__MODULE__}: Incorrect state hash size."}

      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelWithdrawTx : #{inspect(error)}"}
    end
  end

  @doc """
  Gets current state hash.

  ## Example
      iex> Core.Channel.get_current_state_hash(client, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay")
      {:ok, "st_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAArMtts"}
  """
  @spec get_current_state_hash(Client.t(), binary()) ::
          {:ok, binary()} | {:error, String.t() | Error.t()}
  def get_current_state_hash(
        %Client{connection: connection},
        <<"ch_", _bin::binary>> = channel_id
      ) do
    case ChannelAPI.get_channel_by_pubkey(connection, channel_id) do
      {:ok, %Channel{state_hash: state_hash}} -> {:ok, state_hash}
      {:ok, %Error{} = error} -> {:error, error}
      error -> error
    end
  end

  @doc """
  Serialize the list of fields to RLP transaction binary, adds signatures and post it to the node.

  ## Example
      iex> tx = %AeternityNode.Model.ChannelCreateTx{
                  channel_reserve: 1000,
                  delegate_ids: [],
                  fee: 17480000000,
                  initiator_amount: 1000,
                  initiator_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                  lock_period: 100,
                  nonce: 2,
                  push_amount: 1000,
                  responder_amount: 1000,
                  responder_id: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
                  state_hash: "st_11111111111111111111111111111111273Yts",
                  ttl: 0
                }
      iex> Core.Channel.post(client, tx, [signatures_list: [signature1, signature2]])
      {:ok,
        %{
          block_hash: "mh_23unT6UB5U1DycXrYdAfVAumuXQqTsnccrMNp3w6hYW3Wry4X",
          block_height: 206,
          channel_id: "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay",
          tx_hash: "th_2f2sTv4z8R6QZknnCKhqvnHLiQKrAiBqME1nVV8sbGyeYWrSQ3"
        }
  """
  @spec post(Client.t(), struct(), list() | :no_signatures) :: {:ok, map()} | {:error, String.t()}
  def post(client, tx, opts \\ []) do
    post_(client, tx,
      signatures_list: Keyword.get(opts, :signatures_list, :no_signatures),
      inner_tx: Keyword.get(opts, :inner_tx, :no_inner_tx)
    )
  end

  ## POST Basic account + Basic account
  defp post_(%Client{connection: connection} = client, tx,
         signatures_list: signatures_list,
         inner_tx: :no_inner_tx
       )
       when is_list(signatures_list) do
    sig_list = :lists.sort(signatures_list)
    {:ok, %{height: height}} = AeternityNode.Api.Chain.get_current_key_block_height(connection)
    {:ok, res} = Transaction.try_post(client, tx, nil, height, sig_list)

    case tx do
      %ChannelCreateTx{} ->
        {:ok, channel_id} = compute_channel_id(tx.initiator_id, tx.nonce, tx.responder_id)
        {:ok, Map.put(res, :channel_id, channel_id)}

      _ ->
        {:ok, res}
    end
  end

  defp post_(client, tx, opts_list) do
    {:error,
     "#{__MODULE__}: Invalid posting of #{inspect(tx)} , with given client: #{inspect(client)} ,  and options list: #{
       inspect(opts_list)
     }"}
  end

  defp compute_channel_id(<<"ak_", initiator::binary>>, nonce, <<"ak_", responder::binary>>)
       when is_integer(nonce) do
    decoded_initiator = Encoding.decode_base58c(initiator)
    decoded_responder = Encoding.decode_base58c(responder)
    {:ok, hash} = Hash.hash(decoded_initiator <> <<nonce::256>> <> decoded_responder)
    {:ok, Encoding.prefix_encode_base58c("ch", hash)}
  end

  defp compute_channel_id(
         <<"ak_", initiator::binary>> = encoded_ga_id,
         auth_data,
         <<"ak_", responder::binary>>
       )
       when is_binary(auth_data) do
    decoded_initiator = Encoding.decode_base58c(initiator)
    decoded_responder = Encoding.decode_base58c(responder)

    {:ok, auth_id} =
      GeneralizedAccount.compute_auth_id(%{ga_id: encoded_ga_id, auth_data: auth_data})

    {:ok, hash} = Hash.hash(decoded_initiator <> auth_id <> decoded_responder)
    {:ok, Encoding.prefix_encode_base58c("ch", hash)}
  end

  defp compute_channel_id(initiator, nonce, responder) do
    {:error,
     "#{__MODULE__}: Can't compute channel id with given initiator_id: #{initiator}, nonce: #{
       inspect(nonce)
     } and responder_id: #{responder} "}
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
