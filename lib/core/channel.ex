defmodule AeppSDK.Channel do
  @moduledoc """
  Module for Aeternity Channel System, see: [https://github.com/aeternity/protocol/blob/master/channels/README.md](https://github.com/aeternity/protocol/blob/master/channels/README.md)
  Contains all channel-related functionality.

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
      iex> AeppSDK.Channel.get_by_pubkey(client, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C")
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
             AeppSDK.Channel.create(client1, initiator_amt, client5.keypair.public, responder_amt, 1, 20, 10,
                AeppSDK.Utils.Encoding.prefix_encode_base58c(
                 "st", <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                  185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>))
      iex> {:ok, [^create_tx, create_sig1]} = AeppSDK.Utils.Transaction.sign_tx(create_tx, client2)
      iex> {:ok, %{channel_id: channel_id}} = AeppSDK.Channel.post(client1, create_tx, signatures_list: [create_sig, create_sig1])
      {:ok,
         %{
           block_hash: "mh_yqm5TQjwtB5sxhDCSbDJk59VXyd1VMVViA2JtEsNBaGqaLm49",
           block_height: 619,
           channel_id: "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
           tx_hash: "th_VZFXHi74qS66J3Q8EE76sYHWA3GTmbsiPs6ZfrSiViLBpuvx3"
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
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :delegate_ids, []),
             nonce,
             encoded_state_hash
           ),
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(client.connection),
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
      iex> {:ok, [close_mutual_tx, close_mutual_sig]} =
              AeppSDK.Channel.close_mutual(client1, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C", 0, 70_000_000_000)
      iex> {:ok, [^close_mutual_tx, close_mutual_sig1]} = AeppSDK.Utils.Transaction.sign_tx(close_mutual_tx, client2)
      iex> Channel.post(client1, close_mutual_tx, signatures_list: [close_mutual_sig, close_mutual_sig1])
      {:ok,
          %{
            block_hash: "mh_kk1Xzo8GEmpdnAz4yZPXngcLGWjRYnGBAZ4ZtFoPHNHioJ7Di",
            block_height: 574,
            info: %{reason: "Channel not found"},
            tx_hash: "th_t7z2VjPFPr54XD8mwdtojm62ZL6NmLkdJzgsmGWTdSaGqc4Ab"
          }}
  """
  @spec close_mutual(Client.t(), binary(), non_neg_integer(), non_neg_integer(), list()) ::
          {:ok, list()} | {:error, String.t()}
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
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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

  ## Example
      iex> AeppSDK.Channel.close_solo(
               client1,
               "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
               <<>>,
               accounts:
                 {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184, 167,
                    123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54, 240>>,
                  %{
                    cache:
                      {3,
                       {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184,
                          167, 123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54,
                          240>>,
                        [
                          <<>>,
                          <<>>,
                          <<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                            118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                            112, 176>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                           118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                           112, 176>>,
                         [
                           <<58, 133, 242, 134, 182, 11, 142, 227, 118, 190, 131, 89, 37, 214,
                             172, 21, 185, 76, 99, 179, 208, 237, 151, 8, 252, 98, 249, 187, 209,
                             221, 224, 123>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil,
                         {<<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          [
                            <<52, 59, 178, 233, 41, 108, 254, 39, 58, 13, 5, 102, 220, 192, 118,
                              248, 248, 238, 240, 246, 15, 217, 118, 130, 254, 64, 228, 109, 180,
                              158, 30, 72>>,
                            <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                          ], nil, nil}}, nil}}
                  }}
                 )

      {:ok,
          %{
            block_hash: "mh_2cfm1y1zokwu467fLdZrp2VWgNZaTmeXGGw4jHdQGh6sZZctrd",
            block_height: 74,
            info: %{
              channel_amount: 100000000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
              initiator_amount: 30000000000,
              initiator_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
              lock_period: 10,
              locked_until: 106,
              responder_amount: 70000000000,
              responder_id: "ak_GxXeeEKHfiK3f6qR8Rdt6ik1xYviC3z6SN3kMzKiUfQrjpz1B",
              round: 1,
              solo_round: 0,
              state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
            },
            tx_hash: "th_276gHMqrNWX7ucMTokWz5eUEV4cgreumvXB5casY1cNVKKApYD"
          }}
  """
  @spec close_solo(Client.t(), binary(), binary(), list(), list()) ::
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
      when valid_prefixes(sender_prefix, channel_prefix) and is_list(poi) and is_binary(payload) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
         {:ok, response} <-
           Transaction.try_post(
             client,
             %{close_solo_tx | fee: fee},
             Keyword.get(opts, :auth, nil),
             height
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
             AeppSDK.Channel.deposit(client1, 16740000000, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C", 2,
                AeppSDK.Utils.Encoding.prefix_encode_base58c(
                  "st", <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                   185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>))
      iex> {:ok, [^deposit_tx, deposit_sig1]} = AeppSDK.Utils.Transaction.sign_tx(deposit_tx, client2)
      iex> AeppSDK.Channel.post(client1, deposit_tx, signatures_list: [deposit_sig, deposit_sig1])
      {:ok,
          %{
            block_hash: "mh_rRcR3puQg4iAuBkR9yCfJtJTN5nzuaoqvr3oJdENXcyPQPTbY",
            block_height: 947,
            info: %{
              channel_amount: 116720000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
              initiator_amount: 30000000000,
              initiator_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
              lock_period: 10,
              locked_until: 0,
              responder_amount: 70000000000,
              responder_id: "ak_GxXeeEKHfiK3f6qR8Rdt6ik1xYviC3z6SN3kMzKiUfQrjpz1B",
              round: 2,
              solo_round: 0,
              state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
            },
            tx_hash: "th_LxmSCW1jHdaKiHJ32WidK8n2VyeJfarLzYsDA8N9DhN54HJMJ"
          }}
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
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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

  ## Example
      iex> AeppSDK.Channel.settle(client, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C", initiator_amt, responder_amt)
      {:ok,
       %{
         block_hash: "mh_5793UoBfCJUiMGKMMmfPxqZTJPo44HM3HCSBtjwVj8JyVntL6",
         block_height: 299,
         info: %{reason: "Channel not found"},
         tx_hash: "th_2DGD2VmRZ798LxRxTb8TcqzLaEgtuZUk5VJtUvC9MsPzHEELEc"
       }}
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
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
         {:ok, response} <-
           Transaction.try_post(
             client,
             %{settle_tx | fee: fee},
             Keyword.get(opts, :auth, nil),
             height
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
      iex> AeppSDK.Channel.slash(
               client, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
               <<248, 211, 11, 1, 248, 132, 184, 64, 103, 143, 97, 54, 143, 62, 96, 188, 175, 138,
                 69, 94, 189, 154, 187, 232, 24, 124, 227, 118, 222, 228, 194, 201, 138, 30, 163,
                 139, 234, 56, 102, 49, 147, 29, 134, 97, 135, 69, 62, 62, 89, 133, 45, 99, 164,
                 238, 174, 83, 132, 129, 253, 64, 92, 8, 33, 203, 46, 197, 115, 87, 191, 250, 221,
                 0, 184, 64, 218, 115, 120, 42, 135, 32, 185, 172, 64, 147, 81, 28, 252, 62, 61,
                 174, 23, 187, 214, 191, 235, 45, 229, 160, 92, 36, 8, 248, 130, 109, 163, 27, 57,
                 181, 80, 131, 182, 231, 33, 13, 76, 193, 217, 176, 176, 134, 228, 122, 52, 81,
                 237, 128, 105, 191, 57, 99, 140, 104, 242, 118, 170, 157, 214, 6, 184, 73, 248,
                 71, 57, 1, 161, 6, 79, 170, 117, 156, 23, 1, 16, 54, 197, 235, 149, 116, 88, 255,
                 224, 120, 70, 14, 30, 170, 25, 182, 198, 157, 53, 41, 226, 230, 204, 75, 170,
                 223, 3, 192, 160, 104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46,
                 166, 249, 5, 206, 185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144,
                 107>>,
               accounts:
                 {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184, 167,
                    123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54, 240>>,
                  %{
                    cache:
                      {3,
                       {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184,
                          167, 123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54,
                          240>>,
                        [
                          <<>>,
                          <<>>,
                          <<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                            118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                            112, 176>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                           118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                           112, 176>>,
                         [
                           <<58, 133, 242, 134, 182, 11, 142, 227, 118, 190, 131, 89, 37, 214,
                             172, 21, 185, 76, 99, 179, 208, 237, 151, 8, 252, 98, 249, 187, 209,
                             221, 224, 123>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil,
                         {<<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          [
                            <<52, 59, 178, 233, 41, 108, 254, 39, 58, 13, 5, 102, 220, 192, 118,
                              248, 248, 238, 240, 246, 15, 217, 118, 130, 254, 64, 228, 109, 180,
                              158, 30, 72>>,
                            <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                          ], nil, nil}}, nil}}
                  }}
             )

      {:ok,
          %{
            block_hash: "mh_oVXWg8Ws7vLJocaobvbK54RdTkQqPzz34whk7t2XnqTRCEHJV",
            block_height: 193,
            info: %{
              channel_amount: 100000000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
              initiator_amount: 30000000000,
              initiator_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
              lock_period: 10,
              locked_until: 203,
              responder_amount: 70000000000,
              responder_id: "ak_GxXeeEKHfiK3f6qR8Rdt6ik1xYviC3z6SN3kMzKiUfQrjpz1B",
              round: 3,
              solo_round: 0,
              state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
            },
            tx_hash: "th_3XdMojFEg5kMSVwpxCKLXfjtnp5dfzerNYyuYTAp5ypwxedHy"
          }}
  """
  @spec slash(Client.t(), binary(), binary() | map(), list(), list()) ::
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
      when valid_prefixes(sender_prefix, channel_prefix) and is_list(poi) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
         {:ok, response} <-
           Transaction.try_post(
             client,
             %{slash_tx | fee: fee},
             Keyword.get(opts, :auth, nil),
             height
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
     iex> Channel.snapshot_solo(
               client,
               "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
               <<248, 211, 11, 1, 248, 132, 184, 64, 189, 85, 177, 158, 63, 228, 58, 49, 130, 243,
                 140, 226, 243, 148, 27, 45, 181, 131, 160, 118, 17, 83, 57, 252, 79, 125, 17, 66,
                 24, 141, 36, 201, 246, 103, 197, 220, 243, 55, 208, 220, 242, 184, 218, 232, 239,
                 180, 68, 197, 198, 67, 148, 46, 244, 215, 183, 104, 6, 116, 105, 147, 163, 30,
                 71, 8, 184, 64, 56, 168, 162, 166, 91, 36, 180, 37, 49, 220, 215, 99, 239, 45,
                 121, 175, 128, 207, 45, 52, 168, 149, 50, 107, 38, 226, 64, 63, 54, 236, 238,
                 150, 104, 159, 232, 14, 24, 134, 12, 33, 108, 232, 158, 222, 210, 242, 63, 78,
                 134, 146, 242, 211, 11, 122, 230, 252, 254, 103, 150, 139, 88, 80, 47, 6, 184,
                 73, 248, 71, 57, 1, 161, 6, 76, 31, 36, 226, 145, 19, 154, 231, 247, 12, 200,
                 250, 255, 20, 63, 23, 196, 86, 255, 190, 186, 6, 111, 186, 119, 166, 86, 126, 7,
                 231, 197, 244, 43, 192, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43>>
             )
      {:ok,
          %{
            block_hash: "mh_Xwp5ZAU3i8dQNxSSuUEtyBSwy8tjvjiHExYQHKSf32Wq3mtXn",
            block_height: 391,
            tx_hash: "th_2PqtPUxY2gzBrTmkYP3ZKDtbPH5HjZFQtitAJMBqGa6Pa2yuLT"
          }}
  """
  @spec snapshot_solo(Client.t(), binary(), binary() | map(), list()) ::
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
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
  Withdraws locked tokens from channel.
  More information at https://github.com/aeternity/protocol/blob/master/channels/ON-CHAIN.md#channel_withdraw

  ## Example
      iex> {:ok, [withdraw_tx, withdraw_sig]} =
             AeppSDK.Channel.withdraw(client1, "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C", client4.keypair.public, 30000000000,
                AeppSDK.Utils.Encoding.prefix_encode_base58c(
                  "st", <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                   185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>), 3)
      iex> {:ok, [^withdraw_tx, withdraw_sig1]} = AeppSDK.Utils.Transaction.sign_tx(withdraw_tx, client2)
      iex> AeppSDK.Channel.post(client1, withdraw_tx, signatures_list: [withdraw_sig, withdraw_sig1])
      {:ok,
          %{
            block_hash: "mh_2V4FWJtsu7YJ8MnyTCGV56B8aAR5sgbgmMD99GgZQds7BBko1L",
            block_height: 1575,
            info: %{
              channel_amount: 86720000000,
              channel_reserve: 20,
              delegate_ids: [],
              id: "ch_c5xXgW54ZkJHcN8iQ8j6zSyUWqSFJ9XgP9PHV7fiiL8og5K1C",
              initiator_amount: 30000000000,
              initiator_id: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
              lock_period: 10,
              locked_until: 0,
              responder_amount: 70000000000,
              responder_id: "ak_GxXeeEKHfiK3f6qR8Rdt6ik1xYviC3z6SN3kMzKiUfQrjpz1B",
              round: 3,
              solo_round: 0,
              state_hash: "st_aCjRv7ZrunE31mKFLqb5Bc65HkE9ocKMXaPWHCx+kGtBh/0M"
            },
            tx_hash: "th_227fHhhY1A9iqSnNwGgmPU5dWi25r8exZ9JhdG4h6EKLwgBK5K"
          }}
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
          {:ok, list()} | {:error, String.t()}
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
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
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
      iex> AeppSDK.Channel.get_current_state_hash(client, "ch_27i3QZiotznX4LiVKzpUhUZmTYeEC18vREioxJxSN93ckn4Gay")
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
      iex> AeppSDK.Channel.post(client, tx, [signatures_list: [signature1, signature2]])
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
  defp post_(%Client{connection: connection} = client, tx,
         signatures_list: signatures_list,
         inner_tx: :no_inner_tx,
         tx: :no_tx
       )
       when is_list(signatures_list) do
    sig_list = :lists.sort(signatures_list)
    {:ok, %{height: height}} = Chain.get_current_key_block_height(connection)
    {:ok, res} = Transaction.try_post(client, tx, nil, height, sig_list)
    channel_info(client, tx, res)
  end

  # POST GA + GA
  defp post_(%Client{} = client, meta_tx,
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

        {:ok, %PostTxResponse{tx_hash: tx_hash}} =
          TransactionApi.post_transaction(client.connection, %Tx{
            tx: signed_tx
          })

        {:ok, res} = Transaction.await_mining(client.connection, tx_hash, :no_type)
        channel_info(client, tx, res, meta_tx, inner_meta_tx)

      false ->
        {:error,
         "#{__MODULE__}: Inner transaction does not match with inner transaction provided in meta tx"}
    end
  end

  # POST Basic + GA
  defp post_(
         client,
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

        {:ok, %PostTxResponse{tx_hash: tx_hash}} =
          TransactionApi.post_transaction(client.connection, %Tx{
            tx: signed_tx
          })

        {:ok, res} = Transaction.await_mining(client.connection, tx_hash, :no_type)
        channel_info(client, res, meta_tx, inner_tx)

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
