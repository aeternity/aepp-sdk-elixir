# defmodule AeppSDK.Chain do
#   @moduledoc """
#   Contains all chain-related functionality.

#   In order for its functions to be used, a client must be defined first.
#   Client example can be found at: `AeppSDK.Client.new/4`.
#   """
#   alias AeppSDK.Client
#   alias AeppSDK.Utils.Transaction, as: TransactionUtils
#   alias AeternityNode.Api.Chain, as: ChainApi
#   alias AeternityNode.Api.Debug, as: DebugApi
#   alias AeternityNode.Api.NodeInfo, as: NodeInfoApi
#   alias AeternityNode.Api.Transaction, as: TransactionApi

#   alias AeternityNode.Model.{
#     ContractCallObject,
#     DryRunAccount,
#     DryRunInput,
#     DryRunResult,
#     DryRunResults,
#     Error,
#     Event,
#     Generation,
#     GenericSignedTx,
#     GenericTx,
#     GenericTxs,
#     KeyBlock,
#     MicroBlockHeader,
#     PeerPubKey,
#     Peers,
#     Protocol,
#     PubKey,
#     Status,
#     TxInfoObject
#   }

#   alias AeternityNode.Model.InlineResponse2001, as: HeightResponse
#   alias Tesla.Env

#   @type await_options :: [attempts: non_neg_integer(), interval: non_neg_integer()]
#   @type generic_transaction :: %{version: non_neg_integer(), type: String.t()}
#   @type generic_signed_transaction :: %{
#           tx: generic_transaction(),
#           block_height: non_neg_integer(),
#           block_hash: String.t(),
#           hash: String.t(),
#           signatures: [String.t()]
#         }
#   @type event :: %{address: String.t(), topics: [non_neg_integer()], data: String.t()}
#   @type transaction_info :: %{
#           caller_id: String.t(),
#           caller_nonce: non_neg_integer(),
#           height: non_neg_integer(),
#           contract_id: String.t(),
#           gas_price: non_neg_integer(),
#           gas_used: non_neg_integer(),
#           log: [event()],
#           return_value: String.t(),
#           return_type: String.t()
#         }
#   @type key_block :: %{
#           hash: String.t(),
#           height: non_neg_integer(),
#           prev_hash: String.t(),
#           prev_key_hash: String.t(),
#           state_hash: String.t(),
#           miner: String.t(),
#           beneficiary: String.t(),
#           target: non_neg_integer(),
#           pow: [non_neg_integer()] | nil,
#           nonce: non_neg_integer() | nil,
#           time: non_neg_integer(),
#           version: non_neg_integer(),
#           info: String.t()
#         }
#   @type generation :: %{
#           key_block: key_block(),
#           micro_blocks: [String.t()]
#         }
#   @type micro_block_header :: %{
#           hash: String.t(),
#           height: non_neg_integer(),
#           pof_hash: String.t(),
#           prev_hash: String.t(),
#           prev_key_hash: String.t(),
#           state_hash: String.t(),
#           txs_hash: String.t(),
#           signature: String.t(),
#           time: non_neg_integer(),
#           version: non_neg_integer()
#         }
#   @type dry_run_account :: %{pubkey: String.t(), amount: non_neg_integer()}
#   @type dry_run_result :: %{
#           type: String.t(),
#           result: String.t(),
#           reason: String.t() | nil,
#           call_obj: transaction_info() | nil
#         }
#   @type protocol :: %{
#           version: non_neg_integer(),
#           effective_at_height: non_neg_integer()
#         }
#   @type status :: %{
#           genesis_key_block_hash: String.t(),
#           solutions: non_neg_integer(),
#           difficulty: float(),
#           syncing: boolean(),
#           sync_progress: float() | nil,
#           listening: boolean(),
#           protocols: [protocol()],
#           node_version: String.t(),
#           node_revision: String.t(),
#           peer_count: integer(),
#           pending_transactions_count: non_neg_integer(),
#           network_id: String.t()
#         }
#   @type peers :: %{
#           peers: [String.t()],
#           blocked: [String.t()]
#         }
#   @type node_info :: %{
#           peer_pubkey: String.t() | nil,
#           status: status(),
#           node_beneficiary: String.t(),
#           node_pubkey: String.t(),
#           peers: peers()
#         }

#   @doc """
#   Get the height of the current key block

#   ## Example
#       iex> AeppSDK.Chain.height(client)
#       {:ok, 84535}
#   """
#   @spec height(Client.t()) :: {:ok, non_neg_integer()} | {:error, Env.t()}
#   def height(%Client{connection: connection}) do
#     response = ChainApi.get_current_key_block_height(connection)

#     prepare_result(response)
#   end

#   @doc """
#   Wait for the chain to reach specific height

#   ## Example
#       iex> AeppSDK.Chain.await_height(client, 84590)
#       :ok
#   """
#   @spec await_height(Client.t(), non_neg_integer(), await_options()) ::
#           :ok | {:error, String.t()} | {:error, Env.t()}
#   def await_height(%Client{} = client, height, opts \\ [])
#       when is_integer(height) and height > 0 do
#     await_attempts = Keyword.get(opts, :attempts, TransactionUtils.default_await_attempts())

#     await_attempt_interval =
#       Keyword.get(opts, :interval, TransactionUtils.default_await_attempt_interval())

#     await_height(client, height, await_attempts, await_attempt_interval)
#   end

#   @doc """
#   Wait for a transaction to be mined

#   ## Example
#       iex> transaction_hash = "th_232gp9o5Lm1XZ8SMaDCAnLcvyj2CkDkf5tssfD5yVAoFAnPBm7"
#       iex> AeppSDK.Chain.await_transaction(client, transaction_hash)
#       :ok
#   """
#   @spec await_transaction(Client.t(), String.t(), await_options()) ::
#           :ok | {:error, String.t()} | {:error, Env.t()}
#   def await_transaction(%Client{connection: connection}, tx_hash, opts \\ [])
#       when is_binary(tx_hash) do
#     await_attempts = Keyword.get(opts, :attempts, TransactionUtils.default_await_attempts())

#     await_attempt_interval =
#       Keyword.get(opts, :interval, TransactionUtils.default_await_attempt_interval())

#     await_transaction(connection, tx_hash, await_attempts, await_attempt_interval)
#   end

#   @doc """
#   Get a transaction by hash

#   ## Example
#       iex> tx_hash = "th_6FbthJ3jF2AE6z2SywBtg764tNK9LiBCxRW3RfWhMX68JAygz"
#       iex> AeppSDK.Chain.get_transaction(client, tx_hash)
#       {:ok,
#        %{
#          block_hash: "mh_bZUgGMEvu8kaAEv47xyatNfstvoH54VbrCb93y8J44gr2EsCJ",
#          block_height: 84531,
#          hash: "th_6FbthJ3jF2AE6z2SywBtg764tNK9LiBCxRW3RfWhMX68JAygz",
#          signatures: ["sg_R4q5gvb5c9VgwZPt7zLgPJLV4HFNv6ZHzwBVpKaA1ygApq6JBA1NSDsXPa9WLsrm2nGG5BrCy8iq11xGaSbsppzLZycts"],
#          tx: %{type: "SpendTx", version: 1}
#        }}
#   """
#   @spec get_transaction(Client.t(), String.t()) ::
#           {:ok, generic_signed_transaction()} | {:error, String.t()} | {:error, Env.t()}
#   def get_transaction(%Client{connection: connection}, tx_hash) when is_binary(tx_hash) do
#     response = TransactionApi.get_transaction_by_hash(connection, tx_hash)

#     prepare_result(response)
#   end

#   @doc """
#   Get a transaction info by hash

#   ## Example
#       iex> tx_hash = "th_2jg2P41iGUgNif3Nu1vZ34P1aeSeZq4CWtKhEpr6jeLDoTL4mH"
#       iex> AeppSDK.Chain.get_transaction_info(client, tx_hash)
#       {:ok,
#        %{
#          call_info: %{
#            caller_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#            caller_nonce: 11837,
#            contract_id: "ct_Y5Fjymet5kcequZTNNMjMTUaTnYBWBFsVmoPUGnKCyPsfnDg8",
#            gas_price: 1000000000,
#            gas_used: 1252,
#            height: 84513,
#            log: [],
#            return_type: "ok",
#            return_value: "cb_Xfbg4g=="
#          },
#          ga_info: nil,
#          tx_info: nil
#        }}
#   """
#   @spec get_transaction_info(Client.t(), String.t()) ::
#           {:ok, transaction_info()} | {:error, String.t()} | {:error, Env.t()}
#   def get_transaction_info(%Client{connection: connection}, tx_hash) when is_binary(tx_hash) do
#     response = TransactionApi.get_transaction_info_by_hash(connection, tx_hash)

#     prepare_result(response)
#   end

#   @doc """
#   Get all pending transactions

#   ## Example
#       iex> AeppSDK.Chain.get_pending_transactions(client)
#       {:ok, []}
#   """
#   @spec get_pending_transactions(Client.t()) ::
#           {:ok, list(generic_signed_transaction())} | {:error, Env.t()}
#   def get_pending_transactions(%Client{internal_connection: internal_connection}) do
#     response = TransactionApi.get_pending_transactions(internal_connection)

#     prepare_result(response)
#   end

#   @doc """
#   Get current generation

#   ## Example
#       iex> AeppSDK.Chain.get_current_generation(client)
#       {:ok,
#        %{
#          key_block: %{
#            beneficiary: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
#            hash: "kh_LVmMAyjcTtcLTh76STB9gJoAzpXdZBgwtiYX2rC98tkzRpUt8",
#            height: 84552,
#            info: "cb_AAAAAfy4hFE=",
#            miner: "ak_rPG4k1G8MsbdVdgisDXAs95htP94eYeJHPdotCvdJUbNLXmVz",
#            nonce: 1040728877473258350,
#            pow: [1816785, 4563830, 6535791, 7371744, 15431122, 25810590, 38354710,
#             41068269, 49508987, 61851964, 64661610, 64916450, 73480578, 82460245,
#             84205198, 110560762, 119763104, 126778601, 131361835, 152044373,
#             175440084, 229990565, 232441141, 246507939, 256839457, 267089067,
#             281126946, 297684504, 358409889, 368048805, 374727588, 389428641,
#             395353074, 412257533, 448812603, 460866874, 468707889, 478197976,
#             483791458, 492777525, ...],
#            prev_hash: "mh_ZAX9bfDJVRU4yBZVJBjYHrSpWqEfjvTmjhRReAxMH1Tb4aX6D",
#            prev_key_hash: "kh_sqnNrjX4s7uvwBksHK9hgq736vJvGakoB8DjVgqvzymjEiodP",
#            state_hash: "bs_qPF68kYqsw3qNWscQX883gi4XSRvy8K1AyAo6xKmCe22wYiHq",
#            target: 538023502,
#            time: 1558614496897,
#            version: 3
#          },
#          micro_blocks: []
#        }}
#   """
#   @spec get_current_generation(Client.t()) ::
#           {:ok, generation()} | {:error, String.t()} | {:error, Env.t()}
#   def get_current_generation(%Client{connection: connection}) do
#     response = ChainApi.get_current_generation(connection)

#     prepare_result(response)
#   end

#   @doc """
#   Get a generation by hash

#   ## Example
#       iex> hash = "kh_sqnNrjX4s7uvwBksHK9hgq736vJvGakoB8DjVgqvzymjEiodP"
#       iex> AeppSDK.Chain.get_generation(client, hash)
#       {:ok,
#        %{
#          key_block: %{
#            beneficiary: "ak_QFqo5LsvnCxdMK184Rf8aeuQa5JWGf3n8dex2iSGqYE3mzWFn",
#            hash: "kh_sqnNrjX4s7uvwBksHK9hgq736vJvGakoB8DjVgqvzymjEiodP",
#            height: 84551,
#            info: "cb_AAAAAfy4hFE=",
#            miner: "ak_22cVmvsZq8vLxMTZjWcggZ5HQQi2RRF7UrAjMwQ5tCd1kCsNBb",
#            nonce: 8590250258,
#            pow: [4270548, 4672365, 26145245, 46020752, 50518165, 61725479, 82664155,
#             101009367, 123337852, 136176634, 152345694, 154969206, 180766968,
#             182806912, 197514003, 198196883, 199214273, 202117489, 202413040,
#             237707860, 261164171, 288613351, 298097639, 304490763, 314326968,
#             348389855, 355561157, 363125716, 364007441, 382373111, 384879255,
#             393259024, 411552709, 427321732, 430989208, 440655342, 468506638,
#             482430386, 488147407, 504275453, ...],
#            prev_hash: "kh_2VZKBkQnR6JTo2WikRoUNtGNgfQD8FsqKAMXfrR8WKxrPd3Zdr",
#            prev_key_hash: "kh_2VZKBkQnR6JTo2WikRoUNtGNgfQD8FsqKAMXfrR8WKxrPd3Zdr",
#            state_hash: "bs_kWVRFL9VqTcBjsT56SHLsJWryemyTJnFwEBzaJ6aA7btYrKZ5",
#            target: 538041170,
#            time: 1558614345333,
#            version: 3
#          },
#          micro_blocks: ["mh_NN4Tr4w6UBEobHucDNAFRn2sba12f9PFtvPDAAe2idBx3Ymsv",
#           "mh_cXozyVg6968P68cWcNGYHsHsGX9yVoZUGc56APx7z3wo2Vzh2",
#           "mh_2XDQytSS9v39aQdBLioXz3pvYrjWFeVcK2hL8xHzj79QL54Lz6",
#           "mh_GDkX5cqPgq4C2W9QpncMAfsUqbVXSh6nrMAKcPtHiAx9uGURf",
#           "mh_59ZnCtvjvp5nT6Q8QfZhnmRkjEy38BcJ3VS47wwMRCDxNYUQE",
#           "mh_ZAX9bfDJVRU4yBZVJBjYHrSpWqEfjvTmjhRReAxMH1Tb4aX6D"]
#        }}
#   """
#   @spec get_generation(Client.t(), String.t()) ::
#           {:ok, generation()} | {:error, String.t()} | {:error, Env.t()}
#   def get_generation(%Client{connection: connection}, hash) when is_binary(hash) do
#     response = ChainApi.get_generation_by_hash(connection, hash)

#     prepare_result(response)
#   end

#   @doc """
#   Get a generation by height

#   ## Example
#       iex> height = 84551
#       iex> AeppSDK.Chain.get_generation(client, height)
#       {:ok,
#        %{
#          key_block: %{
#            beneficiary: "ak_QFqo5LsvnCxdMK184Rf8aeuQa5JWGf3n8dex2iSGqYE3mzWFn",
#            hash: "kh_sqnNrjX4s7uvwBksHK9hgq736vJvGakoB8DjVgqvzymjEiodP",
#            height: 84551,
#            info: "cb_AAAAAfy4hFE=",
#            miner: "ak_22cVmvsZq8vLxMTZjWcggZ5HQQi2RRF7UrAjMwQ5tCd1kCsNBb",
#            nonce: 8590250258,
#            pow: [4270548, 4672365, 26145245, 46020752, 50518165, 61725479, 82664155,
#             101009367, 123337852, 136176634, 152345694, 154969206, 180766968,
#             182806912, 197514003, 198196883, 199214273, 202117489, 202413040,
#             237707860, 261164171, 288613351, 298097639, 304490763, 314326968,
#             348389855, 355561157, 363125716, 364007441, 382373111, 384879255,
#             393259024, 411552709, 427321732, 430989208, 440655342, 468506638,
#             482430386, 488147407, 504275453, ...],
#            prev_hash: "kh_2VZKBkQnR6JTo2WikRoUNtGNgfQD8FsqKAMXfrR8WKxrPd3Zdr",
#            prev_key_hash: "kh_2VZKBkQnR6JTo2WikRoUNtGNgfQD8FsqKAMXfrR8WKxrPd3Zdr",
#            state_hash: "bs_kWVRFL9VqTcBjsT56SHLsJWryemyTJnFwEBzaJ6aA7btYrKZ5",
#            target: 538041170,
#            time: 1558614345333,
#            version: 3
#          },
#          micro_blocks: ["mh_NN4Tr4w6UBEobHucDNAFRn2sba12f9PFtvPDAAe2idBx3Ymsv",
#           "mh_cXozyVg6968P68cWcNGYHsHsGX9yVoZUGc56APx7z3wo2Vzh2",
#           "mh_2XDQytSS9v39aQdBLioXz3pvYrjWFeVcK2hL8xHzj79QL54Lz6",
#           "mh_GDkX5cqPgq4C2W9QpncMAfsUqbVXSh6nrMAKcPtHiAx9uGURf",
#           "mh_59ZnCtvjvp5nT6Q8QfZhnmRkjEy38BcJ3VS47wwMRCDxNYUQE",
#           "mh_ZAX9bfDJVRU4yBZVJBjYHrSpWqEfjvTmjhRReAxMH1Tb4aX6D"]
#        }}
#   """
#   @spec get_generation(Client.t(), non_neg_integer()) ::
#           {:ok, generation()} | {:error, String.t()} | {:error, Env.t()}
#   def get_generation(%Client{connection: connection}, height) when is_integer(height) do
#     response = ChainApi.get_generation_by_height(connection, height)

#     prepare_result(response)
#   end

#   @doc """
#   Get a micro block's transactions

#   ## Example
#       iex> micro_block_hash = "mh_2GYkXiDbKGd9bMWL63AiaRbKRNDDHR8womVFzxk5BZP4KGQhgw"
#       iex> AeppSDK.Chain.get_micro_block_transactions(client, micro_block_hash)
#       {:ok,
#        [
#          %{
#            block_hash: "mh_2GYkXiDbKGd9bMWL63AiaRbKRNDDHR8womVFzxk5BZP4KGQhgw",
#            block_height: 84547,
#            hash: "th_2J8Xshv3yR8Rf8mEmUSoT6fk4YJz5oGbpLLqJkPAvV1GWeTK6A",
#            signatures: ["sg_PQffTEQQkf2DPthE2QoeRqAUr53m5BszPBGRrdH21Nfbb1s6SFLyckb9TvNPcWy37sBY5YABNsvvJJFdvetHntAkiXrsM"],
#            tx: %{type: "ContractCreateTx", version: 1}
#          }
#        ]}
#   """
#   @spec get_micro_block_transactions(Client.t(), String.t()) ::
#           {:ok, list(generic_signed_transaction())} | {:error, String.t()} | {:error, Env.t()}
#   def get_micro_block_transactions(%Client{connection: connection}, micro_block_hash)
#       when is_binary(micro_block_hash) do
#     response = ChainApi.get_micro_block_transactions_by_hash(connection, micro_block_hash)

#     prepare_result(response)
#   end

#   @doc """
#   Get a key block by hash

#   ## Example
#       iex> key_block_hash = "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P"
#       iex> AeppSDK.Chain.get_key_block(client, key_block_hash)
#       {:ok,
#        %{
#          beneficiary: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
#          hash: "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P",
#          height: 84547,
#          info: "cb_AAAAAfy4hFE=",
#          miner: "ak_HvaKBash8o8FEKVdm5a8qo2j8vx5NKxH2P4RrQMQGokdjo5C2",
#          nonce: 2093870402648332570,
#          pow: [1290617, 3493169, 6212474, 17228667, 52038371, 120922973, 138413619,
#           159935660, 177319436, 178097802, 207343351, 226920891, 291582142, 313980921,
#           320129338, 320796969, 332416956, 346721320, 348325254, 351068507, 362644921,
#           374166089, 393961637, 393998472, 398351923, 398567840, 405562469, 408022294,
#           408391855, 450435185, 451429065, 451522379, 462140541, 490201848, 500060148,
#           508150414, 508157410, 508331280, 510140909, 516740832, 523867648, ...],
#          prev_hash: "kh_PP5rx6mi69FUhBCyDNtaFkitSaENZ1PTHpsmE5d5JGZCLAzZJ",
#          prev_key_hash: "kh_PP5rx6mi69FUhBCyDNtaFkitSaENZ1PTHpsmE5d5JGZCLAzZJ",
#          state_hash: "bs_2V6HE7ZPTrJeA5tuhefgZZKmFAhRHtrE6CTnyB3THucfX3BPdC",
#          target: 538124450,
#          time: 1558614076955,
#          version: 3
#        }}
#   """
#   @spec get_key_block(Client.t(), String.t()) ::
#           {:ok, key_block()} | {:error, String.t()} | {:error, Env.t()}
#   def get_key_block(%Client{connection: connection}, key_block_hash)
#       when is_binary(key_block_hash) do
#     response = ChainApi.get_key_block_by_hash(connection, key_block_hash)

#     prepare_result(response)
#   end

#   @doc """
#   Get a key block by height

#   ## Example
#       iex> key_block_height = 84547
#       iex> AeppSDK.Chain.get_key_block(client, key_block_height)
#       {:ok,
#        %{
#          beneficiary: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
#          hash: "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P",
#          height: 84547,
#          info: "cb_AAAAAfy4hFE=",
#          miner: "ak_HvaKBash8o8FEKVdm5a8qo2j8vx5NKxH2P4RrQMQGokdjo5C2",
#          nonce: 2093870402648332570,
#          pow: [1290617, 3493169, 6212474, 17228667, 52038371, 120922973, 138413619,
#           159935660, 177319436, 178097802, 207343351, 226920891, 291582142, 313980921,
#           320129338, 320796969, 332416956, 346721320, 348325254, 351068507, 362644921,
#           374166089, 393961637, 393998472, 398351923, 398567840, 405562469, 408022294,
#           408391855, 450435185, 451429065, 451522379, 462140541, 490201848, 500060148,
#           508150414, 508157410, 508331280, 510140909, 516740832, 523867648, ...],
#          prev_hash: "kh_PP5rx6mi69FUhBCyDNtaFkitSaENZ1PTHpsmE5d5JGZCLAzZJ",
#          prev_key_hash: "kh_PP5rx6mi69FUhBCyDNtaFkitSaENZ1PTHpsmE5d5JGZCLAzZJ",
#          state_hash: "bs_2V6HE7ZPTrJeA5tuhefgZZKmFAhRHtrE6CTnyB3THucfX3BPdC",
#          target: 538124450,
#          time: 1558614076955,
#          version: 3
#        }}
#   """
#   @spec get_key_block(Client.t(), non_neg_integer()) ::
#           {:ok, key_block()} | {:error, String.t()} | {:error, Env.t()}
#   def get_key_block(%Client{connection: connection}, key_block_height)
#       when is_integer(key_block_height) do
#     response = ChainApi.get_key_block_by_height(connection, key_block_height)

#     prepare_result(response)
#   end

#   @doc """
#   Get a micro block's header

#   ## Example
#       iex> micro_block_hash = "mh_2GYkXiDbKGd9bMWL63AiaRbKRNDDHR8womVFzxk5BZP4KGQhgw"
#       iex> AeppSDK.Chain.get_micro_block_header(client, micro_block_hash)
#       {:ok,
#        %{
#          hash: "mh_2GYkXiDbKGd9bMWL63AiaRbKRNDDHR8womVFzxk5BZP4KGQhgw",
#          height: 84547,
#          pof_hash: "no_fraud",
#          prev_hash: "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P",
#          prev_key_hash: "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P",
#          signature: "sg_RJN8idvktDbCMmFh1V3pmCaGBcvDNrv4vQ8X8Jbad8oxAuqzHm6Pe4VZxpvrDsopayfVjHDMNz36rPVg2iMTyuoaaxwLg",
#          state_hash: "bs_AJscRW9ArzMaWKHqPGGCiDhe7SxnF8a4AdWX2gdjhcEpFbS6x",
#          time: 1558614125599,
#          txs_hash: "bx_22QhAmqifutmQ8g7x8kPPvxEANMqiqMwDBAsw7HqzWGxe93tHD",
#          version: 3
#        }}
#   """
#   @spec get_micro_block_header(Client.t(), String.t()) ::
#           {:ok, micro_block_header()} | {:error, String.t()} | {:error, Env.t()}
#   def get_micro_block_header(%Client{connection: connection}, micro_block_hash)
#       when is_binary(micro_block_hash) do
#     response = ChainApi.get_micro_block_header_by_hash(connection, micro_block_hash)

#     prepare_result(response)
#   end

#   @doc """
#   Dry-run transactions on top of a given block

#   ## Example
#       iex> transactions = ["tx_+N8rAaEBC7TteSf5e1HhvLXhNA0SM1sqKxLIvFIh1jxLyznUHmGCIIehBfZ7ZdL+i0DaHZpf8m42K6cj3on94Wg6F2eruDXsh5g6AYcFKtwr02gAAACDD0JAhDuaygC4gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgcMIbP6v40neQ7iIeZN4CbwwLC1JWUjXOkZs8Dc7Wtz4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAhIqvyBw=="]
#       iex> accounts = [
#         %{
#           pubkey: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#           amount: 1651002120672731042209
#         }
#       ]
#       iex> block_hash = "kh_WPQzXtyDiwvUs54N1L88YsLPn51PERHF76bqcMhpT5vnrAEAT"
#       {:ok,
#        [
#          %{
#            call_obj: %{
#              caller_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#              caller_nonce: 8327,
#              contract_id: "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR",
#              gas_price: 1000000000,
#              gas_used: 252,
#              height: 61481,
#              log: [],
#              return_type: "ok",
#              return_value: "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
#            },
#            reason: nil,
#            result: "ok",
#            type: "contract_call"
#          }
#        ]}
#   """
#   @spec dry_run(Client.t(), list(String.t()), list(dry_run_account()), String.t()) ::
#           {:ok, list(dry_run_result())} | {:error, String.t()} | {:error, Env.t()}
#   def dry_run(
#         %Client{internal_connection: internal_connection},
#         transactions,
#         accounts,
#         block_hash
#       )
#       when is_list(transactions) and is_list(accounts) and is_binary(block_hash) do
#     dry_run_accounts =
#       Enum.map(accounts, fn %{pubkey: pubkey, amount: amount} ->
#         %DryRunAccount{pub_key: pubkey, amount: amount}
#       end)

#     input = %DryRunInput{
#       top: block_hash,
#       accounts: dry_run_accounts,
#       txs: transactions
#     }

#     response = DebugApi.dry_run_txs(internal_connection, input)

#     prepare_result(response)
#   end

#   @doc """
#   Get node's info

#   ## Example
#       iex> AeppSDK.Chain.get_node_info(client)
#       {:ok,
#        %{
#          node_beneficiary: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
#          node_pubkey: "ak_24eXUB8mKvfHWhLrRVYC8cx2GXqKqZcTDyAequLkhJiyxrhVcq",
#          peer_pubkey: "pp_RK92f7wt27WbYijumNi69C1YvgRMfSZxBxn3KeGvGTF5sCFBq",
#          peers: %{
#            blocked: [],
#            peers: ["aenode://pp_DMLqy7Zuhoxe2FzpydyQTgwCJ52wouzxtHWsPGo51XDcxc5c8@13.53.161.215:3015",
#             "aenode://pp_FhecVAucSqWJuMKt8vwsrC14G6Cizet9TppFep1PpGLQwQSpw@13.229.148.230:3015",
#             "aenode://pp_RMzsjgNLZMabSns3gWykAUWQaz218zaUzcQqLCtkbH5mQDGp8@54.245.137.153:3015",
#             "aenode://pp_auNgNxce82JNFd33Z4UVoDvNUJEaSUowwW37v681wMnZgsPfw@34.212.120.93:3015",
#             "aenode://pp_27xmgQ4N1E3QwHyoutLtZsHW5DSW4zneQJ3CxT5JbUejxtFuAu@13.250.162.250:3015",
#             "aenode://pp_2JREXVhMur6RHVDPnEomoc8EP1cgmWdgrJMh9Z7j7a7yebAEKs@52.57.34.16:3015",
#             "aenode://pp_2aKzR7Bnz53amwA1oU55nkkKFD19THF3oxVDudLiksVh52Sypb@3.0.201.37:3015",
#             "aenode://pp_2beMZ7ULM3jye6hdSFVtWmBFRpG1mTevDZ4XNDPfKCgpzqH2Ns@3.122.192.245:3015",
#             "aenode://pp_2vFiJ3LMWVchceNnBPQV3p1fzj4Zd4voCQKNKaU16c3M4UCJok@18.236.142.145:3015",
#             "aenode://pp_2vhFb3HtHd1S7ynbpbFnEdph1tnDXFSfu4NGtq46S2eM5HCdbC@18.195.109.60:3015"]
#          },
#          status: %{
#            difficulty: 252791033,
#            genesis_key_block_hash: "kh_wUCideEB8aDtUaiHCtKcfywU6oHZW6gnyci8Mw6S1RSTCnCRu",
#            listening: true,
#            network_id: "ae_uat",
#            node_revision: "a267159203252ddd6964f49e9125f32bce1efbb0",
#            node_version: "3.0.0-rc.1",
#            peer_count: 8841,
#            pending_transactions_count: 0,
#            protocols: [
#              %{effective_at_height: 82900, version: 3},
#              %{effective_at_height: 40900, version: 2},
#              %{effective_at_height: 0, version: 1}
#            ],
#            solutions: 0,
#            sync_progress: 100.0,
#            syncing: false
#          }
#        }}
#   """
#   @spec get_node_info(Client.t()) :: {:ok, node_info()} | {:error, String.t()} | {:error, Env.t()}
#   def get_node_info(%Client{connection: connection, internal_connection: internal_connection}) do
#     with {:ok, %PeerPubKey{pubkey: peer_pubkey}} <-
#            NodeInfoApi.get_peer_pubkey(connection),
#          {:ok, %Status{} = status} <- NodeInfoApi.get_status(connection),
#          {:ok, %PubKey{pub_key: node_beneficiary}} <-
#            NodeInfoApi.get_node_beneficiary(internal_connection),
#          {:ok, %PubKey{pub_key: node_pubkey}} <- NodeInfoApi.get_node_pubkey(internal_connection),
#          {:ok, %Peers{} = peers} <-
#            NodeInfoApi.get_peers(internal_connection) do
#       {:ok,
#        %{
#          peer_pubkey: peer_pubkey,
#          status: struct_to_map_recursive(status),
#          node_beneficiary: node_beneficiary,
#          node_pubkey: node_pubkey,
#          peers: Map.from_struct(peers)
#        }}
#     end
#   end

#   defp await_height(_client, height, 0, _interval),
#     do: {:error, "Timeout: chain didn't reach height #{height}"}

#   defp await_height(client, height, attempts, interval) do
#     Process.sleep(interval)

#     case height(client) do
#       {:ok, ^height} ->
#         :ok

#       {:ok, current_height} when current_height > height ->
#         :ok

#       _ ->
#         await_height(client, height, attempts - 1, interval)
#     end
#   end

#   defp await_transaction(_connection, tx_hash, 0, _interval),
#     do: {:error, "Transaction #{tx_hash} wasn't mined"}

#   defp await_transaction(connection, tx_hash, attempts, interval) do
#     case TransactionApi.get_transaction_by_hash(connection, tx_hash) do
#       {:ok, %GenericSignedTx{block_hash: "none", block_height: -1}} ->
#         await_transaction(connection, tx_hash, attempts - 1, interval)

#       {:ok, %GenericSignedTx{}} ->
#         :ok

#       {:ok, %Error{reason: message}} ->
#         {:error, message}

#       {:error, %Env{} = env} ->
#         {:error, env}
#     end
#   end

#   defp prepare_result({:ok, %HeightResponse{height: height}}) do
#     {:ok, height}
#   end

#   defp prepare_result({:ok, %GenericSignedTx{} = generic_signed_transaction}) do
#     {:ok, struct_to_map_recursive(generic_signed_transaction)}
#   end

#   defp prepare_result(
#          {:ok,
#           %TxInfoObject{call_info: %ContractCallObject{} = contract_call_object} =
#             transaction_info_object}
#        ) do
#     transaction_info_object_map = Map.from_struct(transaction_info_object)

#     {:ok,
#      %{transaction_info_object_map | call_info: struct_to_map_recursive(contract_call_object)}}
#   end

#   defp prepare_result({:ok, %ContractCallObject{} = transaction_info}) do
#     {:ok, struct_to_map_recursive(transaction_info)}
#   end

#   defp prepare_result({:ok, %GenericTxs{transactions: transactions}}) do
#     transactions =
#       Enum.map(transactions, fn generic_signed_transaction ->
#         struct_to_map_recursive(generic_signed_transaction)
#       end)

#     {:ok, transactions}
#   end

#   defp prepare_result({:ok, %Generation{} = generation}) do
#     {:ok, struct_to_map_recursive(generation)}
#   end

#   defp prepare_result({:ok, %KeyBlock{} = key_block}) do
#     {:ok, Map.from_struct(key_block)}
#   end

#   defp prepare_result({:ok, %MicroBlockHeader{} = micro_block_header}) do
#     {:ok, Map.from_struct(micro_block_header)}
#   end

#   defp prepare_result({:ok, %DryRunResults{results: results}}) do
#     results =
#       Enum.map(
#         results,
#         fn dry_run_result ->
#           struct_to_map_recursive(dry_run_result)
#         end
#       )

#     {:ok, results}
#   end

#   defp prepare_result({:ok, %Error{reason: message}}) do
#     {:error, message}
#   end

#   defp prepare_result({:error, _} = error) do
#     error
#   end

#   defp struct_to_map_recursive(
#          %GenericSignedTx{
#            tx: %GenericTx{} = generic_transaction
#          } = generic_signed_transaction
#        ) do
#     generic_transaction_map = Map.from_struct(generic_transaction)
#     generic_signed_transaction_map = Map.from_struct(generic_signed_transaction)

#     %{generic_signed_transaction_map | tx: generic_transaction_map}
#   end

#   defp struct_to_map_recursive(
#          %ContractCallObject{
#            log: log
#          } = contract_call_object
#        ) do
#     log =
#       Enum.map(log, fn %Event{} = event ->
#         Map.from_struct(event)
#       end)

#     contract_call_object_map = Map.from_struct(contract_call_object)

#     %{contract_call_object_map | log: log}
#   end

#   defp struct_to_map_recursive(%Generation{key_block: %KeyBlock{} = key_block} = generation) do
#     key_block_map = Map.from_struct(key_block)
#     generation_map = Map.from_struct(generation)

#     %{generation_map | key_block: key_block_map}
#   end

#   defp struct_to_map_recursive(
#          %DryRunResult{call_obj: %ContractCallObject{} = contract_call_object} = dry_run_result
#        ) do
#     contract_call_object_map = struct_to_map_recursive(contract_call_object)
#     dry_run_result_map = Map.from_struct(dry_run_result)

#     %{dry_run_result_map | call_obj: contract_call_object_map}
#   end

#   defp struct_to_map_recursive(%Status{protocols: protocols} = status) do
#     protocols =
#       Enum.map(protocols, fn %Protocol{} = protocol ->
#         Map.from_struct(protocol)
#       end)

#     status_map = Map.from_struct(status)

#     %{status_map | protocols: protocols}
#   end
# end
