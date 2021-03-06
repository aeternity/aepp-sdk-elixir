defmodule AeppSDK.AENS do
  @moduledoc """
  Module for Aeternity Naming System, see: [https://github.com/aeternity/protocol/blob/master/AENS.md](https://github.com/aeternity/protocol/blob/master/AENS.md).
  Contains all naming-related functionality.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `AeppSDK.Client.new/4`.
  """

  alias AeppSDK.Client
  alias AeppSDK.Utils.Account, as: AccountUtils
  alias AeppSDK.Utils.Transaction
  alias AeternityNode.Api.Chain
  alias AeternityNode.Api.NameService

  alias AeternityNode.Model.{
    CommitmentId,
    NameClaimTx,
    NameEntry,
    NamePreclaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx
  }

  @prefix_byte_size 2

  @max_name_ttl 50_000
  @max_client_ttl 86_000
  @label_separator "."
  @allowed_registrars ["chain"]
  @multiplier_14 100_000_000_000_000
  @await_attempt_interval 1_000
  @await_attempts 100_000_000
  @type aens_options :: [fee: non_neg_integer(), ttl: non_neg_integer()]
  @type preclaim_options :: [
          fee: non_neg_integer(),
          ttl: non_neg_integer(),
          salt: atom() | non_neg_integer()
        ]
  @type update_options :: [
          fee: non_neg_integer(),
          ttl: non_neg_integer(),
          pointers: list(),
          client_ttl: non_neg_integer(),
          name_ttl: non_neg_integer()
        ]

  @doc """
  Preclaims a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> AeppSDK.AENS.preclaim(client, name, salt: 149_218_901_844_062_129)
      {:ok,
        %{
          block_hash: "mh_Dumv7aK8Nb8Cedm7z1tMvWDMhVZqoc1VHbEgb1V484tZssK6d",
          block_height: 86,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          name: "a1234567890asdfghjkl.chain",
          name_salt: 149218901844062129,,
          tx_hash: "th_wYo5DLruahJrkFwjH5Jji6HsRMbPZBxeJKmRwg8QEyKVYrXGd"
        }}
  """
  @spec preclaim(Client.t(), String.t(), preclaim_options()) ::
          {:error, String.t()} | {:ok, map()}
  def preclaim(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
          },
          connection: connection,
          internal_connection: internal_connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        name,
        opts \\ []
      )
      when sender_prefix == "ak" do
    name_salt =
      case Keyword.get(opts, :salt, :auto) do
        :auto ->
          <<a::32, b::32, c::32>> = :crypto.strong_rand_bytes(12)
          {state, _} = :rand.seed(:exsplus, {a, b, c})
          :rand.uniform(state.max)

        num when num > 0 ->
          num
      end

    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, %CommitmentId{commitment_id: commitment_id}} <-
           NameService.get_commitment_id(internal_connection, name, name_salt),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, preclaim_tx} <-
           build_preclaim_tx(
             client,
             commitment_id,
             user_fee,
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             preclaim_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{preclaim_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      result =
        response
        |> Map.put(:name, name)
        |> Map.put(:name_salt, name_salt)
        |> Map.put(:client, client)

      {:ok, result}
    else
      error -> error
    end
  end

  @doc """
  Claims a name.

  ## Example
      iex> client |> AeppSDK.AENS.preclaim("a1234567890asdfghjkl.chain") |> AeppSDK.AENS.claim()
      {:ok,
       %{
         block_hash: "mh_YyiddDH57Azdztir1s8zgtLXZpBAK1xNBSisCMxSUSJA4MNE3",
         block_height: 23,
         client: %AeppSDK.Client{
           connection: %Tesla.Client{
             adapter: nil,
             fun: nil,
             post: [],
             pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
           },
           gas_price: 1000000,
           internal_connection: %Tesla.Client{
             adapter: nil,
             fun: nil,
             post: [],
             pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
           },
           keypair: %{
             public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
             secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
           },
           network_id: "my_test"
         },
         name: "a1234567890asdfghjkl.chain",
         tx_hash: "th_257jfXcwXS51z1x3zDBdU5auHTjWPAbhhYJEtAwhM7Aby3Syf4"
       }}
  """
  @spec claim({:ok, map()} | {:error, String.t()}, aens_options()) ::
          {:error, String.t()} | {:ok, map()}
  def claim(preclaim_result, opts \\ [])

  def claim(
        {:ok, preclaim_result},
        opts
      ) do
    attempts = Keyword.get(opts, :await_attempts, @await_attempts)
    claim_attempts(preclaim_result, attempts, opts)
  end

  def claim({:error, _} = error, _opts) do
    error
  end

  @doc """
  Claims a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> name_salt = 149_218_901_844_062_129
      iex> AeppSDK.AENS.claim(client, name, name_salt)
      {:ok,
        %{
          block_hash: "mh_41E9iE61koF8AQLMvjTkRJ3N23yne4UXmqn5jeUn1GDrScV7A",
          block_height: 80,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          name: "a1234567890asdfghjkl.chain",
          tx_hash: "th_257jfXcwXS51z1x3zDBdU5auHTjWPAbhhYJEtAwhM7Aby3Syf4"
        }}
  """
  @spec claim(
          Client.t(),
          String.t(),
          non_neg_integer(),
          aens_options()
        ) ::
          {:error, String.t()} | {:ok, map()}
  def claim(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        name,
        name_salt,
        opts \\ []
      )
      when is_binary(name) and is_integer(name_salt) and sender_prefix == "ak" do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, claim_tx} <-
           build_claim_tx(
             client,
             name,
             name_salt,
             Keyword.get(opts, :name_fee, calculate_name_fee(name)),
             user_fee,
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         new_fee <-
           Transaction.calculate_n_times_fee(
             claim_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{claim_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)

      {:ok, result}
    else
      error -> error
    end
  end

  @doc """
  Updates a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> name_ttl = 49_999
      iex> pointers = [
            {AeppSDK.Utils.Keys.public_key_to_binary("ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"),
             AeppSDK.Utils.Serialization.id_to_record(
               AeppSDK.Utils.Keys.public_key_to_binary("ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"),
               :account
             )}]
      iex> client_ttl = 50_000
      iex> client |> AeppSDK.AENS.preclaim(name) |> AeppSDK.AENS.claim() |> AeppSDK.AENS.update(pointers: pointers, name_ttl: name_ttl,  client_ttl: client_ttl)
      {:ok,
        %{
          block_hash: "mh_bDauziEPcfsqZQMyBqLX2grxiD9p9iorsF2utsaCZQtwrEX2T",
          block_height: 41,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          client_ttl: 50000,
          name: "a1234567890asdfghjkl.chain",
          name_ttl: 49999,
          pointers: [
            {<<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
               91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>,
             {:id, :account,
              <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18,
                51, 91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30,
                97>>}}
          ],
          tx_hash: "th_XV3mn79qzc5foq67JuiXWCaCK2yZzbHuk8knvkQtTNMDaa7JB"
        }}
  """
  @spec update(
          {:ok, %{client: AeppSDK.Client.t(), name: binary()}} | {:error, String.t()},
          list()
        ) :: {:error, String.t()} | {:ok, map()}
  def update(
        claim_result,
        opts \\ []
      ) do
    case claim_result do
      {:ok, %{client: client, name: name}} ->
        update_name(client, name, opts)

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Updates a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> name_ttl = 49_999
      iex> pointers = [
            {AeppSDK.Utils.Keys.public_key_to_binary("ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"),
             AeppSDK.Utils.Serialization.id_to_record(
               AeppSDK.Utils.Keys.public_key_to_binary("ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"),
               :account
             )}]
      iex> client_ttl = 50_000
      iex> AeppSDK.AENS.update_name(client, name, name_ttl: name_ttl, pointers: pointers, client_ttl: client_ttl)
      {:ok,
        %{
          block_hash: "mh_bDauziEPcfsqZQMyBqLX2grxiD9p9iorsF2utsaCZQtwrEX2T",
          block_height: 41,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          client_ttl: 50000,
          name: "a1234567890asdfghjkl.chain",
          name_ttl: 49999,
          pointers: [
            {<<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
               91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>,
             {:id, :account,
              <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18,
                51, 91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30,
                97>>}}
          ],
          tx_hash: "th_XV3mn79qzc5foq67JuiXWCaCK2yZzbHuk8knvkQtTNMDaa7JB"
        }}
  """
  @spec update_name(
          Client.t(),
          String.t(),
          update_options()
        ) :: {:error, String.t()} | {:ok, map()}
  def update_name(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        name,
        opts \\ []
      )
      when sender_prefix == "ak" do
    pointers = Keyword.get(opts, :pointers, [])
    client_ttl = Keyword.get(opts, :client_ttl, @max_client_ttl)
    name_ttl = Keyword.get(opts, :name_ttl, @max_name_ttl)
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
         {:ok, update_tx} <-
           build_update_tx(
             client,
             name_id,
             name_ttl,
             pointers,
             client_ttl,
             user_fee,
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         new_fee <-
           Transaction.calculate_n_times_fee(
             update_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{update_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)
        |> Map.put(:pointers, pointers)
        |> Map.put(:client_ttl, client_ttl)
        |> Map.put(:name_ttl, name_ttl)

      {:ok, result}
    else
      error -> error
    end
  end

  @doc """
  Transfers a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> recipient_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
      iex> client |> AeppSDK.AENS.preclaim(name) |> AeppSDK.AENS.claim() |>  AeppSDK.AENS.transfer(recipient_key)
      {:ok,
        %{
          block_hash: "mh_NSyuLSvbB1v4R8nz8ZCLLHQXCHtsBntNyYbWdeKTadFm8Y5nB",
          block_height: 35,
          client: %AeppSDK.Client{
           connection: %Tesla.Client{
             adapter: nil,
             fun: nil,
             post: [],
             pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
           },
           gas_price: 1000000,
           internal_connection: %Tesla.Client{
             adapter: nil,
             fun: nil,
             post: [],
             pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
           },
           keypair: %{
             public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
             secret: "#Function<1.83545712/0 in AeppSDK.Client.new/5>
           },
           network_id: "my_test"
          },
          name: "a1234567890asdfghjkl.chain",
          recipient_id: "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv",
          tx_hash: "th_2Bxxz5j4rexSCRC227oR4E6zBD14MCFh2qhZoNMDiCjzpVv8Qi"
       }}
  """
  @spec transfer(
          {:ok, %{client: AeppSDK.Client.t(), name: binary()} | {:error, String.t()}},
          binary(),
          aens_options()
        ) ::
          {:error, String.t()} | {:ok, map()}
  def transfer(claim_result, recipient_pub_key, opts \\ []) do
    case claim_result do
      {:ok, %{client: client, name: name}} ->
        transfer_name(client, name, recipient_pub_key, opts)

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Transfers a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> recipient_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
      iex> AeppSDK.AENS.transfer_name(client, name, recipient_key)
      {:ok,
        %{
          block_hash: "mh_NSyuLSvbB1v4R8nz8ZCLLHQXCHtsBntNyYbWdeKTadFm8Y5nB",
          block_height: 35,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          name: "a1234567890asdfghjkl.chain",
          recipient_id: "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv",
          tx_hash: "th_2Bxxz5j4rexSCRC227oR4E6zBD14MCFh2qhZoNMDiCjzpVv8Qi"
        }}
  """
  @spec transfer_name(Client.t(), String.t(), String.t(), aens_options()) ::
          {:error, String.t()} | {:ok, map()}
  def transfer_name(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        name,
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
        opts \\ []
      )
      when recipient_prefix == "ak" and sender_prefix == "ak" do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
         {:ok, transfer_tx} <-
           build_transfer_tx(
             client,
             name_id,
             recipient_id,
             user_fee,
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         new_fee <-
           Transaction.calculate_n_times_fee(
             transfer_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{transfer_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)
        |> Map.put(:recipient_id, recipient_id)

      {:ok, result}
    else
      error -> error
    end
  end

  @doc """
  Revokes a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> client |> AeppSDK.AENS.preclaim(name) |> AeppSDK.AENS.claim() |> AeppSDK.AENS.revoke()
      {:ok,
        %{
          block_hash: "mh_21fw4AryJSGKkdaQsigFQwkydfFVbN2mY7G5pRvwq7rp4zmfYC",
          block_height: 24,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          name: "a1234567890asdfghjkl.chain",
          tx_hash: "th_2sGNfvv59tyGEk3fqQSXryzt25uuShA6Zabb3Wjkyt77cWRWFW"
        }}
  """
  @spec revoke({:ok, map()} | {:error, String.t()}, aens_options()) ::
          {:error, String.t()} | {:ok, map()}
  def revoke(claim_result, opts \\ []) do
    case claim_result do
      {:ok, %{client: client, name: name}} ->
        revoke_name(client, name, opts)

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Revokes a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> AeppSDK.AENS.revoke_name(client, name)
      {:ok,
        %{
          block_hash: "mh_21fw4AryJSGKkdaQsigFQwkydfFVbN2mY7G5pRvwq7rp4zmfYC",
          block_height: 24,
          client: %AeppSDK.Client{
            connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3013/v2"]}]
            },
            gas_price: 1000000,
            internal_connection: %Tesla.Client{
              adapter: nil,
              fun: nil,
              post: [],
              pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:3113/v2"]}]
            },
            keypair: %{
              public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
              secret: #Function<1.83545712/0 in AeppSDK.Client.new/5>
            },
            network_id: "my_test"
          },
          name: "a1234567890asdfghjkl.chain",
          tx_hash: "th_2sGNfvv59tyGEk3fqQSXryzt25uuShA6Zabb3Wjkyt77cWRWFW"
        }}
  """
  @spec revoke_name(Client.t(), String.t(), aens_options()) :: {:error, String.t()} | {:ok, map()}
  def revoke_name(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        name,
        opts \\ []
      )
      when sender_prefix == "ak" do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
         {:ok, revoke_tx} <-
           build_revoke_tx(
             client,
             name_id,
             user_fee,
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         new_fee <-
           Transaction.calculate_n_times_fee(
             revoke_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, response} <-
           Transaction.post(
             client,
             %{revoke_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :one_signature
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)

      {:ok, result}
    else
      error -> error
    end
  end

  @doc """
  Validates a name.

  ## Example
      iex> name = "a1234567890asdfghjkl.chain"
      iex> AeppSDK.AENS.validate_name(name)
      {:ok, "a1234567890asdfghjkl.chain"}
  """

  @spec validate_name(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def validate_name(name) do
    case name_parts(name) do
      [_label, ns_registrar] ->
        if Enum.member?(@allowed_registrars, ns_registrar) do
          {:ok, name}
        else
          {:error, :registrar_unknown}
        end

      [_name] ->
        {:error, :no_registrar}

      [_label | _namespaces] ->
        {:error, :multiple_namespaces}
    end
  end

  defp calculate_name_fee(name) when is_binary(name) do
    case validate_name(name) do
      {:ok, _name} ->
        {:ok, ascii_name} = name_to_ascii(name)
        {:ok, domain} = name_domain(ascii_name)

        name_claim_size_fee(byte_size(ascii_name) - byte_size(domain) - 1)

      {:error, _error} = error ->
        error
    end
  end

  defp name_claim_size_fee(size) when size >= 31, do: 3 * @multiplier_14
  defp name_claim_size_fee(30), do: 5 * @multiplier_14
  defp name_claim_size_fee(29), do: 8 * @multiplier_14
  defp name_claim_size_fee(28), do: 13 * @multiplier_14
  defp name_claim_size_fee(27), do: 21 * @multiplier_14
  defp name_claim_size_fee(26), do: 34 * @multiplier_14
  defp name_claim_size_fee(25), do: 55 * @multiplier_14
  defp name_claim_size_fee(24), do: 89 * @multiplier_14
  defp name_claim_size_fee(23), do: 144 * @multiplier_14
  defp name_claim_size_fee(22), do: 233 * @multiplier_14
  defp name_claim_size_fee(21), do: 377 * @multiplier_14
  defp name_claim_size_fee(20), do: 610 * @multiplier_14
  defp name_claim_size_fee(19), do: 987 * @multiplier_14
  defp name_claim_size_fee(18), do: 1_597 * @multiplier_14
  defp name_claim_size_fee(17), do: 2_584 * @multiplier_14
  defp name_claim_size_fee(16), do: 4_181 * @multiplier_14
  defp name_claim_size_fee(15), do: 6_765 * @multiplier_14
  defp name_claim_size_fee(14), do: 10_946 * @multiplier_14
  defp name_claim_size_fee(13), do: 17_711 * @multiplier_14
  defp name_claim_size_fee(12), do: 28_657 * @multiplier_14
  defp name_claim_size_fee(11), do: 46_368 * @multiplier_14
  defp name_claim_size_fee(10), do: 75_025 * @multiplier_14
  defp name_claim_size_fee(9), do: 121_393 * @multiplier_14
  defp name_claim_size_fee(8), do: 196_418 * @multiplier_14
  defp name_claim_size_fee(7), do: 317_811 * @multiplier_14
  defp name_claim_size_fee(6), do: 514_229 * @multiplier_14
  defp name_claim_size_fee(5), do: 832_040 * @multiplier_14
  defp name_claim_size_fee(4), do: 1_346_269 * @multiplier_14
  defp name_claim_size_fee(3), do: 2_178_309 * @multiplier_14
  defp name_claim_size_fee(2), do: 3_524_578 * @multiplier_14
  defp name_claim_size_fee(1), do: 5_702_887 * @multiplier_14

  defp name_to_ascii(name) do
    unicode_list = :unicode.characters_to_list(name, :utf8)

    case :idna.encode(unicode_list, [{:uts46, true}, {:std3_rules, true}]) do
      name_ascii ->
        case length(:string.split(name_ascii, @label_separator, :all)) === 1 do
          true -> {:error, :no_label_in_registrar}
          false -> {:ok, :erlang.list_to_binary(name_ascii)}
        end
    end
  end

  defp name_parts(name) do
    :binary.split(name, @label_separator, [:global, :trim])
  end

  defp name_domain(name) do
    case Enum.reverse(name_parts(name)) do
      [domain | _] -> {:ok, domain}
      _ -> {:error, :invalid_name}
    end
  end

  defp build_preclaim_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection,
           gas_price: gas_price,
           network_id: network_id
         } = client,
         commitment_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(client, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
      preclaim_tx =
        struct(
          NamePreclaimTx,
          account_id: sender_pubkey,
          nonce: nonce,
          commitment_id: commitment_id,
          fee: fee,
          ttl: ttl
        )

      {:ok,
       %{
         preclaim_tx
         | fee: Transaction.calculate_fee(preclaim_tx, height, network_id, fee, gas_price)
       }}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_claim_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection,
           gas_price: gas_price,
           network_id: network_id
         } = client,
         name,
         name_salt,
         name_fee,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(client, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
      claim_tx =
        struct(
          NameClaimTx,
          account_id: sender_pubkey,
          nonce: nonce,
          name: name,
          name_salt: name_salt,
          name_fee: name_fee,
          fee: fee,
          ttl: ttl
        )

      {:ok,
       %{claim_tx | fee: Transaction.calculate_fee(claim_tx, height, network_id, fee, gas_price)}}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_transfer_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           gas_price: gas_price,
           network_id: network_id,
           connection: connection
         } = client,
         name_id,
         recipient_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(client, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
      transfer_tx =
        struct(
          NameTransferTx,
          account_id: sender_pubkey,
          nonce: nonce,
          name_id: name_id,
          recipient_id: recipient_id,
          fee: fee,
          ttl: ttl
        )

      {:ok,
       %{
         transfer_tx
         | fee: Transaction.calculate_fee(transfer_tx, height, network_id, fee, gas_price)
       }}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_update_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           gas_price: gas_price,
           network_id: network_id,
           connection: connection
         } = client,
         name_id,
         name_ttl,
         pointers,
         client_ttl,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(client, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
      name_update_tx =
        struct(
          NameUpdateTx,
          account_id: sender_pubkey,
          nonce: nonce,
          name_id: name_id,
          pointers: pointers,
          name_ttl: name_ttl,
          client_ttl: client_ttl,
          fee: fee,
          ttl: ttl
        )

      {:ok,
       %{
         name_update_tx
         | fee: Transaction.calculate_fee(name_update_tx, height, network_id, fee, gas_price)
       }}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_revoke_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           gas_price: gas_price,
           network_id: network_id,
           connection: connection
         } = client,
         name_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(client, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
      revoke_tx =
        struct(
          NameRevokeTx,
          account_id: sender_pubkey,
          nonce: nonce,
          name_id: name_id,
          fee: fee,
          ttl: ttl
        )

      {:ok,
       %{
         revoke_tx
         | fee: Transaction.calculate_fee(revoke_tx, height, network_id, fee, gas_price)
       }}
    else
      {:error, _info} = error -> error
    end
  end

  defp claim_attempts(_preclaim_result, 0, _opts) do
    {:error,
     "Could not reach next keyblock height, needed to post claim transaction within the given time, aborting..."}
  end

  defp claim_attempts(
         %{
           block_height: block_height,
           client: %Client{connection: connection} = client,
           name: name,
           name_salt: name_salt
         } = preclaim_result,
         attempts,
         opts
       ) do
    Process.sleep(@await_attempt_interval)
    {:ok, %{height: height}} = Chain.get_current_key_block_height(connection)

    if block_height < height do
      claim(client, name, name_salt, opts)
    else
      claim_attempts(preclaim_result, attempts - 1, opts)
    end
  end
end
