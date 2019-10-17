defmodule AeppSDK.Channel.OnChain do
  @moduledoc """
  Module for Aeternity On-Chain channel system, see: [https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md](https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md)
  Contains On-Chain channel-related functionality.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """

  alias AeppSDK.Client
  alias AeppSDK.GeneralizedAccount
  alias AeppSDK.Utils.Account, as: AccountUtils
  alias AeppSDK.Utils.{Encoding, Hash, Serialization, Transaction}

  alias AeternityNode.Api.Chain
  alias AeternityNode.Api.Channel, as: ChannelAPI
  alias AeternityNode.Api.Transaction, as: TransactionApi

  alias AeternityNode.Model.{
    Channel,
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelCreateTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx,
    Error,
    PostTxResponse,
    Tx
  }

  @prefix_byte_size 2
  @state_hash_byte_size 32
  @all_trees_names [:accounts, :calls, :channels, :contracts, :ns, :oracles]
  @empty_tree_hash <<0::256>>
  @poi_version 1

  defguard valid_prefixes(sender_pubkey_prefix, channel_prefix)
           when sender_pubkey_prefix == "ak" and channel_prefix == "ch"

  @doc """
  Gets channel information by its pubkey.

  ## Example
      iex> AeppSDK.Channel.OnChain.get_by_pubkey(client, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C")
      {:ok,
          %{
            channel_amount: 100000000000,
            channel_reserve: 20,
            delegate_ids: [],
            id: "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
            initiator_amount: 30000000000,
            initiator_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
            lock_period: 10,
            locked_until: 0,
            responder_amount: 70000000000,
            responder_id: "ak_GxXeeEKHfiK3f6qR8Rdt6ik1xYviC3z6SN3kMzKiUfQrjpz1B",
            round: 1,
            solo_round: 0,
            state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
          }}
  """
  @spec get_by_pubkey(AeppSDK.Client.t(), String.t()) ::
          {:error, Tesla.Env.t()} | {:ok, map()}
  def get_by_pubkey(%Client{connection: connection}, channel_pubkey) do
    prepare_result(ChannelAPI.get_channel_by_pubkey(connection, channel_pubkey))
  end

  @doc """
  Creates a channel.
  More information at [https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_create](https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_create)

  ## Example
      iex> initiator_amt = 30_000_000_000
      iex> responder_amt = 70_000_000_000
      iex> {:ok, [create_tx, create_sig]} =
             AeppSDK.Channel.OnChain.create(client1, initiator_amt, client2.keypair.public, responder_amt, 1, 20, 10,
                AeppSDK.Utils.Encoding.prefix_encode_base58c(
                 "st", <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                  185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>))
      iex> {:ok, [^create_tx, create_sig1]} = AeppSDK.Utils.Transaction.sign_tx(create_tx, client2)
      iex> {:ok, %{channel_id: channel_id}} = AeppSDK.Channel.OnChain.post(client1, create_tx, signatures_list: [create_sig, create_sig1])
      {:ok,
         %{
           block_hash: "mh_2CwWebt7UpAu5RuwiCTatWA4BXddUM4xSTED3dRxdzs6FjFzY2",
           block_height: 55,
           channel_id: "ch_2WxZjGhqPurmGQrVtJ2LkzgNK4xEg6KViAhd6t9sHRKCiwws3a",
           tx_hash: "th_2PkYGBQJxDNhsWKs5yGQ41wP2y32HHiN4qwNUpcbKiGd1n1rdx"
          }}
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
        ) :: {:ok, list()} | {:error, String.t()}
  def create(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
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
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
             user_fee,
             Keyword.get(opts, :delegate_ids, []),
             nonce,
             encoded_state_hash
           ),
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(client.connection),
         new_fee <-
           Transaction.calculate_n_times_fee(
             create_channel_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{create_channel_tx | fee: new_fee},
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
      iex> {:ok, [close_mutual_tx, close_mutual_sig]} =
              AeppSDK.Channel.OnChain.close_mutual(client1, "ch_2WxZjGhqPurmGQrVtJ2LkzgNK4xEg6KViAhd6t9sHRKCiwws3a", 0, 70_000_000_000)
      iex> {:ok, [^close_mutual_tx, close_mutual_sig1]} = AeppSDK.Utils.Transaction.sign_tx(close_mutual_tx, client2)
      iex> AeppSDK.Channel.OnChain.post(client1, close_mutual_tx, signatures_list: [close_mutual_sig, close_mutual_sig1])
      {:ok,
          %{
            block_hash: "mh_2rhgaqaHC8Xiroamfd6rNfRRemjpVdWBJY1jfTS1F2Gub3fU14",
            block_height: 136,
            info: %{reason: "Channel not found"},
            tx_hash: "th_2DW1XZRUdYmojKVU8yQDzMgq2jupFL8ZgANzLsseiGAsUq4s4Z"
      }}
  """
  @spec close_mutual(Client.t(), binary(), non_neg_integer(), non_neg_integer(), list()) ::
          {:ok, list()} | {:error, String.t()}
  def close_mutual(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        initiator_amount_final,
        responder_amount_final,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) and initiator_amount_final >= 0 and
             responder_amount_final >= 0 do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, close_mutual_tx} <-
           build_close_mutual_tx(
             channel_id,
             user_fee,
             sender_pubkey,
             initiator_amount_final,
             nonce,
             responder_amount_final,
             Keyword.get(opts, :ttl, 0)
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             close_mutual_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{close_mutual_tx | fee: new_fee},
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

  ## Example
      iex> AeppSDK.Channel.OnChain.close_solo(
               client,
               channel_id,
               <<248, 210, 11, 1, 248, 132, 184, 64, 201, 113, 103, 241, 42, 81, 62, 1, 103, 105,
                 22, 251, 213, 10, 40, 106, 197, 217, 39, 51, 5, 44, 73, 142, 50, 78, 40, 208, 88,
                 116, 43, 53, 81, 6, 23, 241, 250, 225, 60, 76, 4, 174, 160, 24, 130, 33, 72, 1,
                 185, 121, 0, 233, 109, 122, 143, 66, 188, 5, 160, 35, 142, 26, 220, 2, 184, 64,
                 90, 28, 241, 181, 193, 50, 161, 54, 69, 243, 124, 105, 122, 228, 172, 8, 199,
                 166, 32, 131, 229, 16, 81, 237, 37, 44, 86, 1, 202, 62, 176, 168, 89, 137, 245,
                 105, 120, 166, 242, 61, 238, 182, 172, 144, 224, 208, 122, 177, 35, 133, 90, 76,
                 250, 235, 23, 132, 124, 23, 226, 16, 137, 50, 85, 5, 184, 72, 248, 70, 57, 2,
                 161, 6, 67, 28, 253, 157, 52, 56, 167, 245, 195, 204, 105, 111, 179, 9, 174, 138,
                 170, 157, 22, 18, 121, 142, 124, 182, 178, 196, 189, 31, 111, 81, 64, 49, 2, 160,
                 154, 233, 243, 226, 108, 37, 138, 14, 209, 86, 39, 89, 167, 191, 182, 94, 106,
                 233, 189, 108, 94, 31, 187, 28, 192, 85, 168, 253, 98, 98, 99, 158>>,
               accounts:
                 {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73, 245,
                    75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212, 51>>,
                  %{
                    cache:
                      {3,
                       {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73,
                          245, 75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212,
                          51>>,
                        [
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                            105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                            16>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                            52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                           105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                           16>>,
                         [
                           <<60, 23, 175, 26, 217, 146, 152, 11, 103, 81, 151, 214, 147, 110, 187,
                             210, 92, 78, 171, 45, 72, 28, 247, 161, 167, 18, 61, 234, 180, 217,
                             133, 6>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil, nil},
                        {<<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                           52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                         [
                           <<51, 216, 132, 73, 112, 198, 24, 252, 160, 107, 12, 223, 138, 22, 165,
                             77, 67, 150, 195, 81, 35, 223, 36, 71, 96, 42, 48, 91, 69, 136, 247,
                             142>>,
                           <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                         ], nil, nil}}}
                  }}
             )

      {:ok,
          %{
            block_hash: "mh_JnaZ2mMaVLxGw4hooGB1chTpgh6ifokC9h4xqgdbRMGvACibX",
            block_height: 111,
            info: %{
              channel_amount: 100000000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_WZKRxaPhrfBZ1mKD5gLnU9jxrW9u3gjJNBCJ4hndEiNKs9CND",
              initiator_amount: 30000000000,
              initiator_id: "ak_hZP2M8FamBSM6kNoMVwFK3JEsy4fZ9e7pRAw7HXKrSUg3B8nQ",
              lock_period: 10,
              locked_until: 121,
              responder_amount: 70000000000,
              responder_id: "ak_287XG6Fied7M1W54mAtTnEzWbAPn6zHSf5Y84wXtp4nQBS7vmv",
              round: 2,
              solo_round: 0,
              state_hash: "st_munz4mwlig7RVidZp7+2XmrpvWxeH7scwFWo/WJiY55yXpaq"
            },
            tx_hash: "th_2X8iGZkZvavsmG8udFENqnfqsKrYyBBpAuif7RZoZUUog8Y7Yq"
      }}
  """
  @spec close_solo(Client.t(), binary(), binary(), list(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def close_solo(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        payload,
        poi,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) and is_list(poi) and is_binary(payload) do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, close_solo_tx} <-
           build_close_solo_tx(
             channel_id,
             user_fee,
             sender_pubkey,
             nonce,
             payload,
             poi,
             Keyword.get(opts, :ttl, 0)
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             close_solo_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{close_solo_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      {:ok, channel_info} = get_by_pubkey(client, channel_id)
      {:ok, Map.put(response, :info, channel_info)}
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelCloseSoloTx : #{inspect(error)}"}
    end
  end

  @doc """
  Deposits funds into a channel after creation
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_deposit

  ## Example
      iex> {:ok, [deposit_tx, deposit_sig]} =
             AeppSDK.Channel.OnChain.deposit(client1, 16_740_000_000, "ch_215kMreHiB59G3CdfH8ySffdbbJz7eFeLRMxGnVZTt75pHndjK", 2,
                AeppSDK.Utils.Encoding.prefix_encode_base58c(
                  "st", <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                   185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>))
      iex> {:ok, [^deposit_tx, deposit_sig1]} = AeppSDK.Utils.Transaction.sign_tx(deposit_tx, client2)
      iex> AeppSDK.Channel.OnChain.post(client1, deposit_tx, signatures_list: [deposit_sig, deposit_sig1])
      {:ok,
          %{
            block_hash: "mh_ZFvg7gqiZrAyrcAn1RPM7mi2e1CFmq4f5wfauwdiARoDFep4F",
            block_height: 280,
            info: %{
              channel_amount: 116740000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_215kMreHiB59G3CdfH8ySffdbbJz7eFeLRMxGnVZTt75pHndjK",
              initiator_amount: 30000000000,
              initiator_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              lock_period: 10,
              locked_until: 0,
              responder_amount: 70000000000,
              responder_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
              round: 2,
              solo_round: 0,
              state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
            },
          tx_hash: "th_279M3NYh19PfHCmnWZpYXTaFf6PVfbB5aZe5TazjTNUiTSaVsZ"
      }}
  """
  @spec deposit(Client.t(), non_neg_integer(), binary(), non_neg_integer(), binary(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def deposit(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        amount,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        round,
        <<"st_", state_hash::binary>> = encoded_state_hash,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
         {:ok, deposit_tx} <-
           build_deposit_tx(
             amount,
             channel_id,
             user_fee,
             sender_pubkey,
             nonce,
             round,
             encoded_state_hash,
             Keyword.get(opts, :ttl, 0)
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             deposit_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{deposit_tx | fee: new_fee},
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
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
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
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
         {:ok, force_progress_tx} <-
           build_force_progress_tx(
             channel_id,
             user_fee,
             sender_pubkey,
             nonce,
             offchain_trees,
             payload,
             round,
             encoded_state_hash,
             Keyword.get(opts, :ttl, 0),
             update
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             force_progress_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _response} = response <-
           Transaction.post(
             client,
             %{force_progress_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
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

  ## Example
      iex> AeppSDK.Channel.OnChain.settle(client, channel_id, initiator_amt, responder_amt)
      {:ok,
       %{
         block_hash: "mh_jH89m5ACnV5rsoo1vhg5D6jTXThotcY48B1DWADF8A7kFCvTf",
         block_height: 255,
         info: %{reason: "Channel not found"},
         tx_hash: "th_2NubsEBfPPF2cup9Hd9zuu9Evy9V1EHGhxS1D8eVinBZRL4CcC"
      }}
  """
  @spec settle(Client.t(), binary(), non_neg_integer(), non_neg_integer(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def settle(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        initiator_amount_final,
        responder_amount_final,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, settle_tx} <-
           build_settle_tx(
             channel_id,
             user_fee,
             sender_pubkey,
             initiator_amount_final,
             nonce,
             responder_amount_final,
             Keyword.get(opts, :ttl, 0)
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             settle_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{settle_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      {:ok, channel_info} = get_by_pubkey(client, channel_id)
      {:ok, Map.put(response, :info, channel_info)}
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelSettleTx : #{inspect(error)}"}
    end
  end

  @doc """
  If a malicious party sent a channel_close_solo or channel_force_progress_tx with an outdated state,
  the honest party has the opportunity to issue a channel_slash transaction
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_slash

  ## Example
      iex> AeppSDK.Channel.OnChain.slash(
               client,
               channel_id,
               <<248, 210, 11, 1, 248, 132, 184, 64, 145, 148, 30, 197, 5, 240, 183, 26, 184, 110,
                 253, 83, 1, 240, 198, 71, 193, 214, 193, 22, 202, 70, 234, 30, 157, 24, 219, 67,
                 15, 0, 223, 68, 118, 143, 137, 154, 195, 231, 18, 82, 28, 33, 169, 105, 139, 44,
                 139, 184, 115, 249, 149, 202, 50, 234, 107, 252, 10, 163, 184, 236, 43, 84, 34,
                 11, 184, 64, 232, 63, 222, 177, 255, 229, 215, 175, 11, 119, 122, 12, 47, 88,
                 143, 199, 191, 170, 176, 3, 163, 44, 192, 125, 35, 127, 69, 169, 247, 201, 234,
                 1, 204, 85, 143, 19, 156, 213, 69, 155, 252, 218, 91, 162, 99, 192, 26, 71, 122,
                 199, 100, 141, 109, 8, 158, 38, 100, 121, 194, 189, 237, 160, 78, 0, 184, 72,
                 248, 70, 57, 2, 161, 6, 67, 28, 253, 157, 52, 56, 167, 245, 195, 204, 105, 111,
                 179, 9, 174, 138, 170, 157, 22, 18, 121, 142, 124, 182, 178, 196, 189, 31, 111,
                 81, 64, 49, 3, 160, 154, 233, 243, 226, 108, 37, 138, 14, 209, 86, 39, 89, 167,
                 191, 182, 94, 106, 233, 189, 108, 94, 31, 187, 28, 192, 85, 168, 253, 98, 98, 99,
                 158>>,
               accounts:
                 {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73, 245,
                    75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212, 51>>,
                  %{
                    cache:
                      {3,
                       {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73,
                          245, 75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212,
                          51>>,
                        [
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                            105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                            16>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                            52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                           105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                           16>>,
                         [
                           <<60, 23, 175, 26, 217, 146, 152, 11, 103, 81, 151, 214, 147, 110, 187,
                             210, 92, 78, 171, 45, 72, 28, 247, 161, 167, 18, 61, 234, 180, 217,
                             133, 6>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil, nil},
                        {<<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                           52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                         [
                           <<51, 216, 132, 73, 112, 198, 24, 252, 160, 107, 12, 223, 138, 22, 165,
                             77, 67, 150, 195, 81, 35, 223, 36, 71, 96, 42, 48, 91, 69, 136, 247,
                             142>>,
                           <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                         ], nil, nil}}}
                  }}
             )

      {:ok,
          %{
            block_hash: "mh_azf8sDtinbauus1qK9f2o1h6EePUiuNt12ZqZFwWrR8J3JCsC",
            block_height: 181,
            info: %{
              channel_amount: 100000000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_WZKRxaPhrfBZ1mKD5gLnU9jxrW9u3gjJNBCJ4hndEiNKs9CND",
              initiator_amount: 30000000000,
              initiator_id: "ak_hZP2M8FamBSM6kNoMVwFK3JEsy4fZ9e7pRAw7HXKrSUg3B8nQ",
              lock_period: 10,
              locked_until: 191,
              responder_amount: 70000000000,
              responder_id: "ak_287XG6Fied7M1W54mAtTnEzWbAPn6zHSf5Y84wXtp4nQBS7vmv",
              round: 3,
              solo_round: 0,
              state_hash: "st_munz4mwlig7RVidZp7+2XmrpvWxeH7scwFWo/WJiY55yXpaq"
          },
          tx_hash: "th_hgEEnpcjPdLk5CEdmeXETmQTYcHvuVBnMi5d85kPRBawGQLek"
      }}
  """
  @spec slash(Client.t(), binary(), binary() | map(), list(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def slash(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        payload,
        poi,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) and is_list(poi) do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, slash_tx} <-
           build_slash_tx(
             channel_id,
             user_fee,
             sender_pubkey,
             nonce,
             payload,
             poi,
             Keyword.get(opts, :ttl, 0)
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             slash_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{slash_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      {:ok, channel_info} = get_by_pubkey(client, channel_id)
      {:ok, Map.put(response, :info, channel_info)}
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

  ## Example
     iex> AeppSDK.Channel.OnChain.snapshot_solo(
               client,
               channel_id,
               <<248, 210, 11, 1, 248, 132, 184, 64, 198, 42, 55, 37, 192, 126, 199, 229, 22, 222,
                 103, 86, 51, 29, 17, 238, 229, 17, 124, 160, 247, 28, 39, 30, 186, 138, 206, 3,
                 179, 46, 224, 25, 32, 48, 25, 220, 61, 218, 161, 170, 122, 123, 30, 8, 122, 62,
                 232, 246, 47, 128, 64, 151, 153, 128, 69, 221, 3, 174, 6, 148, 197, 125, 192, 15,
                 184, 64, 33, 185, 19, 26, 171, 135, 138, 163, 121, 250, 122, 152, 34, 168, 11,
                 254, 89, 49, 219, 158, 93, 207, 98, 1, 229, 10, 163, 193, 8, 10, 81, 82, 239, 13,
                 219, 133, 175, 134, 76, 195, 134, 43, 166, 76, 59, 36, 53, 83, 120, 238, 252,
                 229, 166, 219, 165, 153, 61, 214, 128, 86, 52, 137, 51, 14, 184, 72, 248, 70, 57,
                 2, 161, 6, 245, 169, 216, 57, 28, 40, 9, 221, 141, 60, 227, 220, 162, 91, 220,
                 255, 107, 28, 150, 170, 195, 164, 93, 50, 116, 244, 179, 80, 127, 154, 153, 182,
                 43, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 43>>
             )

      {:ok,
          %{
            block_hash: "mh_k84aBRvAYSQSxpWVj6ZJ9Z4wiUJhcAStoBLpRkLM1u7U74PZo",
            block_height: 112,
            tx_hash: "th_2AAhNgLfWdy5MoPhagi39mAXY5YgBn3i5E611D3stWVD8GxKbT"
      }}
  """
  @spec snapshot_solo(Client.t(), binary(), binary() | map(), list()) ::
          {:ok, map()} | {:error, String.t()}
  def snapshot_solo(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        payload,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, snapshot_solo_tx} <-
           build_snapshot_solo_tx(
             channel_id,
             sender_pubkey,
             payload,
             Keyword.get(opts, :ttl, 0),
             user_fee,
             nonce
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             snapshot_solo_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _response} = response <-
           Transaction.post(
             client,
             %{snapshot_solo_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      response
    else
      error ->
        {:error, "#{__MODULE__}: Unsuccessful post of ChannelSnapshotSoloTx : #{inspect(error)}"}
    end
  end

  @doc """
  Withdraws locked tokens from channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_withdraw

  ## Example
      iex> {:ok, [withdraw_tx, withdraw_sig]} =
             AeppSDK.Channel.OnChain.withdraw(client1, "ch_215kMreHiB59G3CdfH8ySffdbbJz7eFeLRMxGnVZTt75pHndjK", 30_000_000_000,
                AeppSDK.Utils.Encoding.prefix_encode_base58c(
                  "st", <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                   185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>), 3)
      iex> {:ok, [^withdraw_tx, withdraw_sig1]} = AeppSDK.Utils.Transaction.sign_tx(withdraw_tx, client2)
      iex> AeppSDK.Channel.OnChain.post(client1, withdraw_tx, signatures_list: [withdraw_sig, withdraw_sig1])
      {:ok,
          %{
            block_hash: "mh_EhHcf36PdKcfAgBB1A7yhxpYFVqTLwk1xNFYZ1oNYjNHkUcNt",
            block_height: 419,
            info: %{
              channel_amount: 86740000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_215kMreHiB59G3CdfH8ySffdbbJz7eFeLRMxGnVZTt75pHndjK",
              initiator_amount: 30000000000,
              initiator_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              lock_period: 10,
              locked_until: 0,
              responder_amount: 70000000000,
              responder_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
              round: 3,
              solo_round: 0,
              state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
            },
          tx_hash: "th_232xnsXwTmU49oCbu6NK7wvG9c84KybkDUXE3TjuGvqNkNBZob
      }}
  """
  @spec withdraw(
          Client.t(),
          binary(),
          binary(),
          non_neg_integer(),
          non_neg_integer(),
          list()
        ) ::
          {:ok, list()} | {:error, String.t()}
  def withdraw(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<channel_prefix::binary-size(@prefix_byte_size), _::binary>> = channel_id,
        amount,
        <<"st_", state_hash::binary>> = encoded_state_hash,
        round,
        opts \\ []
      )
      when valid_prefixes(sender_prefix, channel_prefix) do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         decoded_state_hash <- Encoding.decode_base58c(state_hash),
         true <- byte_size(decoded_state_hash) == @state_hash_byte_size,
         {:ok, withdraw_tx} <-
           build_withdraw_tx(
             channel_id,
             sender_pubkey,
             amount,
             Keyword.get(opts, :ttl, 0),
             user_fee,
             nonce,
             encoded_state_hash,
             round
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             withdraw_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _} = res <-
           Transaction.sign_tx(
             %{withdraw_tx | fee: new_fee},
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
      iex> AeppSDK.Channel.OnChain.get_current_state_hash(client, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay")
      {:ok, "st_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAArMtts"}
  """
  @spec get_current_state_hash(Client.t(), String.t()) ::
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
    Calculates state hash by provided Proof of Inclusion

    ## Example
      iex> poi = [accounts:
                 {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73, 245,
                    75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212, 51>>,
                  %{
                    cache:
                      {3,
                       {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73,
                          245, 75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212,
                          51>>,
                        [
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                            105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                            16>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                            52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                           105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                           16>>,
                         [
                           <<60, 23, 175, 26, 217, 146, 152, 11, 103, 81, 151, 214, 147, 110, 187,
                             210, 92, 78, 171, 45, 72, 28, 247, 161, 167, 18, 61, 234, 180, 217,
                             133, 6>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil, nil},
                        {<<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                           52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                         [
                           <<51, 216, 132, 73, 112, 198, 24, 252, 160, 107, 12, 223, 138, 22, 165,
                             77, 67, 150, 195, 81, 35, 223, 36, 71, 96, 42, 48, 91, 69, 136, 247,
                             142>>,
                           <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                         ], nil, nil}}}
                  }}]
      iex> AeppSDK.Channel.OnChain.calculate_state_hash(poi)
      {:ok, "st_2BE4tgcWqnLJZjECoYgwnbB1awSgNYzGrunNs5MmWEKWaMFCbT"}
  """
  @spec calculate_state_hash(Serialization.poi_keyword()) :: {:ok, binary()}
  def calculate_state_hash(poi) when is_list(poi) do
    packed_state_hashes =
      for tree <- @all_trees_names, into: <<@poi_version::64>> do
        {state_hash, _proof_db} = Keyword.get(poi, tree, {@empty_tree_hash, %{cache: {0, nil}}})
        state_hash
      end

    {:ok, state_hash} = Hash.hash(packed_state_hashes)

    {:ok, Encoding.prefix_encode_base58c("st", state_hash)}
  end

  @doc """
  Serialize the list of fields to RLP transaction binary, adds signatures and post it to the node.

  ## Example
      iex> tx = %AeternityNode.Model.ChannelCreateTx{
                  channel_reserve: 20,
                  delegate_ids: [],
                  fee: 17_560_000_000,
                  initiator_amount: 30_000_000_000,
                  initiator_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
                  lock_period: 10,
                  nonce: 2,
                  push_amount: 1,
                  responder_amount: 70_000_000_000,
                  responder_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
                  state_hash: "st_nscaNBmydKEvrWB6492mkpCmptuSExd38Hwf3uvZUCGqKBFU7",
                  ttl: 0
                }
      iex> signature1 = <<65,111,24,149,206,121,117,82,192,205,237,44,184,94,82,204,236,
                          214,24,128,168,113,9,99,104,18,70,147,215,52,233,8,189,150,213,
                          80,108,8,50,196,106,17,117,204,215,161,175,38,249,220,34,77,226,
                          164,212,11,242,80,51,82,211,34,97,15>>
      iex> signature2 = <<169,216,194,56,20,98,158,150,54,133,124,227,96,40,230,236,185,
                          181,186,48,175,65,130,110,39,254,244,18,155,153,210,170,181,249,
                          138,249,130,239,245,1,2,164,44,146,105,193,61,79,105,71,176,166,
                          30,137,239,84,138,188,8,92,182,83,130,1>>
      iex> AeppSDK.Channel.OnChain.post(client, tx, [signatures_list: [signature1, signature2]])
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
      inner_tx: Keyword.get(opts, :inner_tx, :no_inner_tx),
      tx: Keyword.get(opts, :tx, :no_tx)
    )
  end

  # POST Basic + Basic
  defp post_(%Client{} = client, tx,
         signatures_list: signatures_list,
         inner_tx: :no_inner_tx,
         tx: :no_tx
       )
       when is_list(signatures_list) do
    sig_list = :lists.sort(signatures_list)

    case Transaction.post(client, tx, :no_auth, sig_list) do
      {:ok, res} ->
        channel_info(client, tx, res)

      {:error, _} = err ->
        err
    end
  end

  # POST GA + GA
  defp post_(%Client{connection: connection} = client, meta_tx,
         signatures_list: :no_signatures,
         inner_tx: inner_meta_tx,
         tx: tx
       )
       when is_map(inner_meta_tx) do
    case inner_meta_tx.tx ===
           Serialization.serialize([[], Serialization.serialize(tx)], :signed_tx) do
      true ->
        new_serialized_inner_tx = wrap_in_signature_signed_tx(inner_meta_tx, [])

        new_meta_tx = %{meta_tx | tx: new_serialized_inner_tx}

        signed_tx =
          Encoding.prefix_encode_base64(
            "tx",
            wrap_in_signature_signed_tx(new_meta_tx, [])
          )

        with {:ok, %PostTxResponse{tx_hash: tx_hash}} <-
               TransactionApi.post_transaction(connection, %Tx{
                 tx: signed_tx
               }),
             {:ok, res} <- Transaction.await_mining(connection, tx_hash, :no_type) do
          channel_info(client, tx, res, meta_tx, inner_meta_tx)
        else
          {:error, _} = err -> err
          {:ok, %AeternityNode.Model.Error{} = err} -> {:error, err}
        end

      false ->
        {:error,
         "#{__MODULE__}: Inner transaction does not match with inner transaction provided in meta tx"}
    end
  end

  # POST Basic + GA
  defp post_(
         %Client{connection: connection} = client,
         %{tx: serialized_inner_tx} = meta_tx,
         signatures_list: basic_account_signature,
         inner_tx: inner_tx,
         tx: :no_tx
       )
       when is_list(basic_account_signature) and is_map(inner_tx) do
    case serialized_inner_tx ===
           Serialization.serialize([[], Serialization.serialize(inner_tx)], :signed_tx) do
      true ->
        new_serialized_inner_tx = wrap_in_signature_signed_tx(inner_tx, basic_account_signature)

        new_meta_tx = %{meta_tx | tx: new_serialized_inner_tx}

        signed_tx =
          Encoding.prefix_encode_base64(
            "tx",
            wrap_in_signature_signed_tx(new_meta_tx, [])
          )

        with {:ok, %PostTxResponse{tx_hash: tx_hash}} <-
               TransactionApi.post_transaction(connection, %Tx{
                 tx: signed_tx
               }),
             {:ok, res} <- Transaction.await_mining(connection, tx_hash, :no_type) do
          channel_info(client, res, meta_tx, inner_tx)
        else
          {:error, _} = err -> err
          {:ok, %AeternityNode.Model.Error{} = err} -> {:error, err}
        end

      false ->
        {:error,
         "#{__MODULE__}: Inner transaction does not match with inner transaction provided in meta tx"}
    end
  end

  defp post_(client, tx, opts_list),
    do:
      {:error,
       "#{__MODULE__}: Invalid posting of #{inspect(tx)} , with given client: #{inspect(client)} ,  and options list: #{
         inspect(opts_list)
       }"}

  defp channel_info(client, tx, res) do
    case tx do
      %ChannelCreateTx{} ->
        {:ok, channel_id} = compute_channel_id(tx.initiator_id, tx.nonce, tx.responder_id)
        {:ok, Map.put(res, :channel_id, channel_id)}

      _ ->
        {:ok, channel_info} = get_by_pubkey(client, tx.channel_id)
        {:ok, Map.put(res, :info, channel_info)}
    end
  end

  defp channel_info(client, tx, res, meta_tx, inner_meta_tx) do
    case tx do
      %ChannelCreateTx{} ->
        data = find_initiator_data(meta_tx, inner_meta_tx, tx)
        {:ok, channel_id} = compute_channel_id(tx.initiator_id, data, tx.responder_id)
        {:ok, Map.put(res, :channel_id, channel_id)}

      _ ->
        {:ok, channel_info} = get_by_pubkey(client, tx.channel_id)
        {:ok, Map.put(res, :info, channel_info)}
    end
  end

  defp channel_info(client, res, meta_tx, inner_tx) do
    case inner_tx do
      %ChannelCreateTx{} ->
        {:ok, channel_id} =
          if inner_tx.initiator_id != meta_tx.ga_id do
            compute_channel_id(inner_tx.initiator_id, inner_tx.nonce, inner_tx.responder_id)
          else
            compute_channel_id(
              inner_tx.initiator_id,
              meta_tx.auth_data,
              inner_tx.responder_id
            )
          end

        {:ok, Map.put(res, :channel_id, channel_id)}

      _ ->
        {:ok, channel_info} = get_by_pubkey(client, inner_tx.channel_id)
        {:ok, Map.put(res, :info, channel_info)}
    end
  end

  defp find_initiator_data(%{ga_id: ga_id, auth_data: auth_data}, _meta_tx1, %ChannelCreateTx{
         initiator_id: init_id
       })
       when ga_id === init_id,
       do: auth_data

  defp find_initiator_data(_meta_tx, %{ga_id: ga_id, auth_data: auth_data}, %ChannelCreateTx{
         initiator_id: init_id
       })
       when ga_id === init_id,
       do: auth_data

  defp find_initiator_data(%{ga_id: ga_id}, %{ga_id: ga_id1}, %ChannelCreateTx{
         initiator_id: init_id
       }),
       do:
         {:error,
          "#{__MODULE__}: No match for initiator_id: #{init_id}, ga_id: #{ga_id}, ga_id1: #{
            ga_id1
          }"}

  defp wrap_in_signature_signed_tx(tx, signature_list) do
    serialized_tx = Serialization.serialize(tx)
    signed_tx_fields = [signature_list, serialized_tx]
    Serialization.serialize(signed_tx_fields, :signed_tx)
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

  defp compute_channel_id(initiator, nonce, responder),
    do:
      {:error,
       "#{__MODULE__}: Can't compute channel id with given initiator_id: #{initiator}, nonce: #{
         inspect(nonce)
       } and responder_id: #{responder} "}

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
    serialized_poi = Serialization.serialize_poi(poi)

    {:ok,
     %ChannelCloseSoloTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       nonce: nonce,
       payload: payload,
       poi: serialized_poi,
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
    serialized_poi = Serialization.serialize_poi(poi)

    {:ok,
     %ChannelSlashTx{
       channel_id: channel_id,
       fee: fee,
       from_id: from_id,
       nonce: nonce,
       payload: payload,
       poi: serialized_poi,
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
    {:ok, Map.from_struct(response)}
  end

  defp prepare_result({:error, _} = error) do
    error
  end
end
