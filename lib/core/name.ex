# defmodule AeppSDK.AENS do
#   @moduledoc """
#   Module for Aeternity Naming System, see: [https://github.com/aeternity/protocol/blob/master/AENS.md](https://github.com/aeternity/protocol/blob/master/AENS.md).
#   Contains all naming-related functionality.

#   In order for its functions to be used, a client must be defined first.
#   Client example can be found at: `AeppSDK.Client.new/4`.
#   """

#   alias AeppSDK.Client
#   alias AeppSDK.Utils.Account, as: AccountUtils
#   alias AeppSDK.Utils.Transaction
#   alias AeternityNode.Api.Chain
#   alias AeternityNode.Api.NameService

#   alias AeternityNode.Model.{
#     CommitmentId,
#     NameClaimTx,
#     NameEntry,
#     NamePreclaimTx,
#     NameRevokeTx,
#     NameTransferTx,
#     NameUpdateTx
#   }

#   @prefix_byte_size 2

#   @max_name_ttl 50_000
#   @max_client_ttl 86_000

#   @type aens_options :: [fee: non_neg_integer(), ttl: non_neg_integer()]

#   @doc """
#   Preclaims a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> AeppSDK.AENS.preclaim(client, name)
#       {:ok,
#         %{
#           block_hash: "mh_Dumv7aK8Nb8Cedm7z1tMvWDMhVZqoc1VHbEgb1V484tZssK6d",
#           block_height: 86,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           name: "a123.test",
#           name_salt: 149218901844062129,,
#           tx_hash: "th_wYo5DLruahJrkFwjH5Jji6HsRMbPZBxeJKmRwg8QEyKVYrXGd"
#         }}
#   """
#   @spec preclaim(Client.t(), String.t(), non_neg_integer() | atom(), aens_options()) ::
#           {:error, String.t()} | {:ok, map()}
#   def preclaim(
#         %Client{
#           keypair: %{
#             public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
#           },
#           connection: connection,
#           internal_connection: internal_connection
#         } = client,
#         name,
#         salt \\ :auto,
#         opts \\ []
#       )
#       when sender_prefix == "ak" do
#     name_salt =
#       case salt do
#         :auto ->
#           <<a::32, b::32, c::32>> = :crypto.strong_rand_bytes(12)
#           {state, _} = :rand.seed(:exsplus, {a, b, c})
#           :rand.uniform(state.max)

#         num when num > 0 ->
#           num
#       end

#     with {:ok, %CommitmentId{commitment_id: commitment_id}} <-
#            NameService.get_commitment_id(internal_connection, name, name_salt),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
#          {:ok, preclaim_tx} <-
#            build_preclaim_tx(
#              client,
#              commitment_id,
#              Keyword.get(opts, :fee, 0),
#              Keyword.get(opts, :ttl, Transaction.default_ttl())
#            ),
#          {:ok, response} <-
#            Transaction.try_post(
#              client,
#              preclaim_tx,
#              Keyword.get(opts, :auth, nil),
#              height
#            ) do
#       result =
#         response
#         |> Map.put(:name, name)
#         |> Map.put(:name_salt, name_salt)
#         |> Map.put(:client, client)

#       {:ok, result}
#     else
#       error -> error
#     end
#   end

#   @doc """
#   Claims a name.

#   ## Example
#       iex> client |> AeppSDK.AENS.preclaim("a123.test") |> AeppSDK.AENS.claim()
#       {:ok,
#        %{
#          block_hash: "mh_YyiddDH57Azdztir1s8zgtLXZpBAK1xNBSisCMxSUSJA4MNE3",
#          block_height: 23,
#          client: %AeppSDK.Client{
#            connection: %Tesla.Client{
#              adapter: nil,
#              fun: nil,
#              post: [],
#              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#            },
#            gas_price: 1000000,
#            internal_connection: %Tesla.Client{
#              adapter: nil,
#              fun: nil,
#              post: [],
#              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#            },
#            keypair: %{
#              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#              secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#            },
#            network_id: "my_test"
#          },
#          name: "a123.test",
#          tx_hash: "th_257jfXcwXS51z1x3zDBdU5auHTjWPAbhhYJEtAwhM7Aby3Syf4"
#        }}
#   """
#   @spec claim({:ok, map()} | {:error, String.t()}, aens_options()) ::
#           {:error, String.t()} | {:ok, map()}
#   def claim(preclaim_result, opts \\ []) do
#     case preclaim_result do
#       {:ok, %{client: client, name: name, name_salt: name_salt}} ->
#         claim(client, name, name_salt, opts)

#       {:error, _reason} = error ->
#         error
#     end
#   end

#   @doc """
#   Claims a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> name_salt = 149218901844062129,
#       iex> AeppSDK.AENS.claim(client, name, name_salt)
#       {:ok,
#         %{
#           block_hash: "mh_41E9iE61koF8AQLMvjTkRJ3N23yne4UXmqn5jeUn1GDrScV7A",
#           block_height: 80,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           name: "a123.test",
#           tx_hash: "th_257jfXcwXS51z1x3zDBdU5auHTjWPAbhhYJEtAwhM7Aby3Syf4"
#         }}
#   """
#   @spec claim(Client.t(), String.t(), integer(), aens_options()) ::
#           {:error, String.t()} | {:ok, map()}
#   def claim(
#         %Client{
#           keypair: %{
#             public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
#           },
#           connection: connection
#         } = client,
#         name,
#         name_salt,
#         opts \\ []
#       )
#       when is_binary(name) and is_integer(name_salt) and sender_prefix == "ak" do
#     with {:ok, claim_tx} <-
#            build_claim_tx(
#              client,
#              name,
#              name_salt,
#              Keyword.get(opts, :fee, 0),
#              Keyword.get(opts, :ttl, Transaction.default_ttl())
#            ),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
#          {:ok, response} <-
#            Transaction.try_post(
#              client,
#              claim_tx,
#              Keyword.get(opts, :auth, nil),
#              height
#            ) do
#       result =
#         response
#         |> Map.put(:client, client)
#         |> Map.put(:name, name)

#       {:ok, result}
#     else
#       error -> error
#     end
#   end

#   @doc """
#   Updates a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> name_ttl = 49_999
#       iex> pointers = []
#       iex> client_ttl = 50_000
#       iex> client |> AeppSDK.AENS.preclaim(name) |> AeppSDK.AENS.claim() |> AeppSDK.AENS.update(pointers, name_ttl,  client_ttl)
#       {:ok,
#         %{
#           block_hash: "mh_bDauziEPcfsqZQMyBqLX2grxiD9p9iorsF2utsaCZQtwrEX2T",
#           block_height: 41,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           client_ttl: 50000,
#           name: "a123.test",
#           name_ttl: 49999,
#           pointers: [],
#           tx_hash: "th_XV3mn79qzc5foq67JuiXWCaCK2yZzbHuk8knvkQtTNMDaa7JB"
#         }}
#   """
#   @spec update(
#           {:ok, %{client: AeppSDK.Client.t(), name: binary()}} | {:error, String.t()},
#           list(),
#           non_neg_integer(),
#           non_neg_integer(),
#           aens_options()
#         ) :: {:error, String.t()} | {:ok, map()}
#   def update(
#         claim_result,
#         pointers \\ [],
#         name_ttl \\ @max_name_ttl,
#         client_ttl \\ @max_client_ttl,
#         opts \\ []
#       ) do
#     case claim_result do
#       {:ok, %{client: client, name: name}} ->
#         update_name(client, name, name_ttl, pointers, client_ttl, opts)

#       {:error, _reason} = error ->
#         error
#     end
#   end

#   @doc """
#   Updates a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> name_ttl = 49_999
#       iex> pointers = []
#       iex> client_ttl = 50_000
#       iex> AeppSDK.AENS.update_name(client, name, name_ttl, pointers, client_ttl)
#       {:ok,
#         %{
#           block_hash: "mh_bDauziEPcfsqZQMyBqLX2grxiD9p9iorsF2utsaCZQtwrEX2T",
#           block_height: 41,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           client_ttl: 50000,
#           name: "a123.test",
#           name_ttl: 49999,
#           pointers: [],
#           tx_hash: "th_XV3mn79qzc5foq67JuiXWCaCK2yZzbHuk8knvkQtTNMDaa7JB"
#         }}
#   """
#   @spec update_name(
#           Client.t(),
#           String.t(),
#           non_neg_integer(),
#           list(),
#           non_neg_integer(),
#           aens_options()
#         ) :: {:error, String.t()} | {:ok, map()}
#   def update_name(
#         %Client{
#           keypair: %{
#             public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
#           },
#           connection: connection
#         } = client,
#         name,
#         name_ttl \\ @max_name_ttl,
#         pointers \\ [],
#         client_ttl \\ @max_client_ttl,
#         opts \\ []
#       )
#       when is_integer(name_ttl) and is_integer(client_ttl) and is_list(pointers) and
#              sender_prefix == "ak" do
#     with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
#          {:ok, update_tx} <-
#            build_update_tx(
#              client,
#              name_id,
#              name_ttl,
#              pointers,
#              client_ttl,
#              Keyword.get(opts, :fee, 0),
#              Keyword.get(opts, :ttl, Transaction.default_ttl())
#            ),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
#          {:ok, response} <-
#            Transaction.try_post(
#              client,
#              update_tx,
#              Keyword.get(opts, :auth, nil),
#              height
#            ) do
#       result =
#         response
#         |> Map.put(:client, client)
#         |> Map.put(:name, name)
#         |> Map.put(:pointers, pointers)
#         |> Map.put(:client_ttl, client_ttl)
#         |> Map.put(:name_ttl, name_ttl)

#       {:ok, result}
#     else
#       error -> error
#     end
#   end

#   @doc """
#   Transfers a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> recipient_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
#       iex> client |> AeppSDK.AENS.preclaim(name) |> AeppSDK.AENS.claim() |>  AeppSDK.AENS.transfer(recipient_key)
#       {:ok,
#         %{
#           block_hash: "mh_NSyuLSvbB1v4R8nz8ZCLLHQXCHtsBntNyYbWdeKTadFm8Y5nB",
#           block_height: 35,
#           client: %AeppSDK.Client{
#            connection: %Tesla.Client{
#              adapter: nil,
#              fun: nil,
#              post: [],
#              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#            },
#            gas_price: 1000000,
#            internal_connection: %Tesla.Client{
#              adapter: nil,
#              fun: nil,
#              post: [],
#              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#            },
#            keypair: %{
#              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#              secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#            },
#            network_id: "my_test"
#           },
#           name: "a123.test",
#           recipient_id: "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv",
#           tx_hash: "th_2Bxxz5j4rexSCRC227oR4E6zBD14MCFh2qhZoNMDiCjzpVv8Qi"
#        }}
#   """
#   @spec transfer(
#           {:ok, %{client: AeppSDK.Client.t(), name: binary()} | {:error, String.t()}},
#           binary(),
#           aens_options()
#         ) ::
#           {:error, String.t()} | {:ok, map()}
#   def transfer(claim_result, recipient_pub_key, opts \\ []) do
#     case claim_result do
#       {:ok, %{client: client, name: name}} ->
#         transfer_name(client, name, recipient_pub_key, opts)

#       {:error, _reason} = error ->
#         error
#     end
#   end

#   @doc """
#   Transfers a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> recipient_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
#       iex> AeppSDK.AENS.transfer_name(client, name, recipient_key)
#       {:ok,
#         %{
#           block_hash: "mh_NSyuLSvbB1v4R8nz8ZCLLHQXCHtsBntNyYbWdeKTadFm8Y5nB",
#           block_height: 35,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           name: "a123.test",
#           recipient_id: "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv",
#           tx_hash: "th_2Bxxz5j4rexSCRC227oR4E6zBD14MCFh2qhZoNMDiCjzpVv8Qi"
#         }}
#   """
#   @spec transfer_name(Client.t(), String.t(), binary(), aens_options()) ::
#           {:error, String.t()} | {:ok, map()}
#   def transfer_name(
#         %Client{
#           keypair: %{
#             public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
#           },
#           connection: connection
#         } = client,
#         name,
#         <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
#         opts \\ []
#       )
#       when recipient_prefix == "ak" and sender_prefix == "ak" do
#     with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
#          {:ok, transfer_tx} <-
#            build_transfer_tx(
#              client,
#              name_id,
#              recipient_id,
#              Keyword.get(opts, :fee, 0),
#              Keyword.get(opts, :ttl, Transaction.default_ttl())
#            ),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
#          {:ok, response} <-
#            Transaction.try_post(
#              client,
#              transfer_tx,
#              Keyword.get(opts, :auth, nil),
#              height
#            ) do
#       result =
#         response
#         |> Map.put(:client, client)
#         |> Map.put(:name, name)
#         |> Map.put(:recipient_id, recipient_id)

#       {:ok, result}
#     else
#       error -> error
#     end
#   end

#   @doc """
#   Revokes a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> client |> AeppSDK.AENS.preclaim(name) |> AeppSDK.AENS.claim() |> AeppSDK.AENS.revoke()
#       {:ok,
#         %{
#           block_hash: "mh_21fw4AryJSGKkdaQsigFQwkydfFVbN2mY7G5pRvwq7rp4zmfYC",
#           block_height: 24,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           name: "a123.test",
#           tx_hash: "th_2sGNfvv59tyGEk3fqQSXryzt25uuShA6Zabb3Wjkyt77cWRWFW"
#         }}
#   """
#   @spec revoke({:ok, map()} | {:error, String.t()}, aens_options()) ::
#           {:error, String.t()} | {:ok, map()}
#   def revoke(claim_result, opts \\ []) do
#     case claim_result do
#       {:ok, %{client: client, name: name}} ->
#         revoke_name(client, name, opts)

#       {:error, _reason} = error ->
#         error
#     end
#   end

#   @doc """
#   Revokes a name.

#   ## Example
#       iex> name = "a123.test"
#       iex> AeppSDK.AENS.revoke_name(client, name)
#       {:ok,
#         %{
#           block_hash: "mh_21fw4AryJSGKkdaQsigFQwkydfFVbN2mY7G5pRvwq7rp4zmfYC",
#           block_height: 24,
#           client: %AeppSDK.Client{
#             connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
#             },
#             gas_price: 1000000,
#             internal_connection: %Tesla.Client{
#               adapter: nil,
#               fun: nil,
#               post: [],
#               pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
#             },
#             keypair: %{
#               public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
#               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
#             },
#             network_id: "my_test"
#           },
#           name: "a123.test",
#           tx_hash: "th_2sGNfvv59tyGEk3fqQSXryzt25uuShA6Zabb3Wjkyt77cWRWFW"
#         }}
#   """
#   @spec revoke_name(Client.t(), String.t(), aens_options()) :: {:error, String.t()} | {:ok, map()}
#   def revoke_name(
#         %Client{
#           keypair: %{
#             public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
#           },
#           connection: connection
#         } = client,
#         name,
#         opts \\ []
#       )
#       when sender_prefix == "ak" do
#     with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
#          {:ok, revoke_tx} <-
#            build_revoke_tx(
#              client,
#              name_id,
#              Keyword.get(opts, :fee, 0),
#              Keyword.get(opts, :ttl, Transaction.default_ttl())
#            ),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
#          {:ok, response} <-
#            Transaction.try_post(
#              client,
#              revoke_tx,
#              Keyword.get(opts, :auth, nil),
#              height
#            ) do
#       result =
#         response
#         |> Map.put(:client, client)
#         |> Map.put(:name, name)

#       {:ok, result}
#     else
#       error -> error
#     end
#   end

#   defp build_preclaim_tx(
#          %Client{
#            keypair: %{
#              public: sender_pubkey
#            },
#            connection: connection,
#            gas_price: gas_price,
#            network_id: network_id
#          },
#          commitment_id,
#          fee,
#          ttl
#        ) do
#     with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
#       preclaim_tx =
#         struct(
#           NamePreclaimTx,
#           account_id: sender_pubkey,
#           nonce: nonce,
#           commitment_id: commitment_id,
#           fee: fee,
#           ttl: ttl
#         )

#       {:ok,
#        %{
#          preclaim_tx
#          | fee: Transaction.calculate_fee(preclaim_tx, height, network_id, fee, gas_price)
#        }}
#     else
#       {:error, _info} = error -> error
#     end
#   end

#   defp build_claim_tx(
#          %Client{
#            keypair: %{
#              public: sender_pubkey
#            },
#            connection: connection,
#            gas_price: gas_price,
#            network_id: network_id
#          },
#          name,
#          name_salt,
#          fee,
#          ttl
#        ) do
#     with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
#       claim_tx =
#         struct(
#           NameClaimTx,
#           account_id: sender_pubkey,
#           nonce: nonce,
#           name: name,
#           name_salt: name_salt,
#           fee: fee,
#           ttl: ttl
#         )

#       {:ok,
#        %{claim_tx | fee: Transaction.calculate_fee(claim_tx, height, network_id, fee, gas_price)}}
#     else
#       {:error, _info} = error -> error
#     end
#   end

#   defp build_transfer_tx(
#          %Client{
#            keypair: %{
#              public: sender_pubkey
#            },
#            gas_price: gas_price,
#            network_id: network_id,
#            connection: connection
#          },
#          name_id,
#          recipient_id,
#          fee,
#          ttl
#        ) do
#     with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
#       transfer_tx =
#         struct(
#           NameTransferTx,
#           account_id: sender_pubkey,
#           nonce: nonce,
#           name_id: name_id,
#           recipient_id: recipient_id,
#           fee: fee,
#           ttl: ttl
#         )

#       {:ok,
#        %{
#          transfer_tx
#          | fee: Transaction.calculate_fee(transfer_tx, height, network_id, fee, gas_price)
#        }}
#     else
#       {:error, _info} = error -> error
#     end
#   end

#   defp build_update_tx(
#          %Client{
#            keypair: %{
#              public: sender_pubkey
#            },
#            gas_price: gas_price,
#            network_id: network_id,
#            connection: connection
#          },
#          name_id,
#          name_ttl,
#          pointers,
#          client_ttl,
#          fee,
#          ttl
#        ) do
#     with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
#       name_update_tx =
#         struct(
#           NameUpdateTx,
#           account_id: sender_pubkey,
#           nonce: nonce,
#           name_id: name_id,
#           pointers: pointers,
#           name_ttl: name_ttl,
#           client_ttl: client_ttl,
#           fee: fee,
#           ttl: ttl
#         )

#       {:ok,
#        %{
#          name_update_tx
#          | fee: Transaction.calculate_fee(name_update_tx, height, network_id, fee, gas_price)
#        }}
#     else
#       {:error, _info} = error -> error
#     end
#   end

#   defp build_revoke_tx(
#          %Client{
#            keypair: %{
#              public: sender_pubkey
#            },
#            gas_price: gas_price,
#            network_id: network_id,
#            connection: connection
#          },
#          name_id,
#          fee,
#          ttl
#        ) do
#     with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_pubkey),
#          {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
#       revoke_tx =
#         struct(
#           NameRevokeTx,
#           account_id: sender_pubkey,
#           nonce: nonce,
#           name_id: name_id,
#           fee: fee,
#           ttl: ttl
#         )

#       {:ok,
#        %{
#          revoke_tx
#          | fee: Transaction.calculate_fee(revoke_tx, height, network_id, fee, gas_price)
#        }}
#     else
#       {:error, _info} = error -> error
#     end
#   end
# end
