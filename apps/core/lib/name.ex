defmodule Core.AENS do
  @moduledoc """
  Aeternity Naming System: https://github.com/aeternity/protocol/blob/master/AENS.md
  Contains all name-related functionality

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `Core.Client.new/4`
  """
  alias AeternityNode.Model.{
    NamePreclaimTx,
    NameClaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx,
    CommitmentId,
    NameEntry
  }

  alias AeternityNode.Api.NameService
  alias AeternityNode.Api.Chain
  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.Transaction

  @prefix_byte_size 2

  @doc """
  Preclaims a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_salt = 7
      iex> Core.AENS.preclaim(client, name, name_salt)
      {:ok,
        %{
          block_hash: "mh_Dumv7aK8Nb8Cedm7z1tMvWDMhVZqoc1VHbEgb1V484tZssK6d",
          block_height: 86,
          client: %Core.Client{
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
              secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
            },
            network_id: "my_test"
          },
          name: "a123.test",
          name_salt: 7,
          tx_hash: "th_wYo5DLruahJrkFwjH5Jji6HsRMbPZBxeJKmRwg8QEyKVYrXGd"
        }}
  """
  @spec preclaim(Client.t(), String.t(), non_neg_integer(), list()) ::
          {:error, String.t()} | {:ok, map()}
  def preclaim(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          internal_connection: internal_connection,
          gas_price: gas_price
        } = client,
        name,
        name_salt,
        opts \\ []
      )
      when sender_prefix == "ak" do
    with {:ok, %CommitmentId{commitment_id: commitment_id}} <-
           NameService.get_commitment_id(internal_connection, name, name_salt),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, preclaim_tx} <-
           build_preclaim_tx(
             client,
             commitment_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             preclaim_tx,
             height
           ) do
      result =
        response
        |> Map.put(:name, name)
        |> Map.put(:name_salt, name_salt)
        |> Map.put(:client, client)

      {:ok, result}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NamePreclaimTx : #{inspect(error)}"}
    end
  end

  @doc """
  Claims a name.

  ## Examples
      iex> client |> Core.AENS.preclaim(name, name_salt) |> Core.AENS.claim()
      {:ok,
       %{
         block_hash: "mh_YyiddDH57Azdztir1s8zgtLXZpBAK1xNBSisCMxSUSJA4MNE3",
         block_height: 23,
         client: %Core.Client{
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
             secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
           },
           network_id: "my_test"
         },
         name: "a123.test",
         tx_hash: "th_257jfXcwXS51z1x3zDBdU5auHTjWPAbhhYJEtAwhM7Aby3Syf4"
       }}

  """
  @spec claim({:ok, map()}, list) :: {:error, String.t()} | {:ok, map()}
  def claim({:ok, %{client: client, name: name, name_salt: name_salt}}, opts \\ []) do
    claim(client, name, name_salt, opts)
  end

  @doc """
  Claims a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_salt = 7
      iex> Core.AENS.claim(client, name, name_salt)
       {:ok,
         %{
           block_hash: "mh_41E9iE61koF8AQLMvjTkRJ3N23yne4UXmqn5jeUn1GDrScV7A",
           block_height: 80,
           client: %Core.Client{
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
               secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
             },
             network_id: "my_test"
           },
           name: "a123.test",
           tx_hash: "th_257jfXcwXS51z1x3zDBdU5auHTjWPAbhhYJEtAwhM7Aby3Syf4"
         }}
  """

  @spec claim(Client.t(), String.t(), integer(), list()) :: {:error, String.t()} | {:ok, map()}
  def claim(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        } = client,
        name,
        name_salt,
        opts \\ []
      )
      when is_binary(name) and is_integer(name_salt) and sender_prefix == "ak" do
    with {:ok, claim_tx} <-
           build_claim_tx(
             client,
             name,
             name_salt,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             claim_tx,
             height
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)

      {:ok, result}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameClaimTx: #{inspect(error)} "}
    end
  end

  @doc """
  Updates a name.

  ## Examples
      iex> name_ttl = 49_999
      iex> pointers = []
      iex> client_ttl = 50_000
      iex> client |> Core.AENS.preclaim(name, name_salt) |> Core.AENS.claim() |> Core.AENS.update(name_ttl, pointers, client_ttl)
      {:ok,
       %{
         block_hash: "mh_Ssw5f2cta5Dv1i6PvSSRf7FnzyCVRq2Mfkefmnu8Egagyg5Eg",
         block_height: 134,
         tx_hash: "th_XV3mn79qzc5foq67JuiXWCaCK2yZzbHuk8knvkQtTNMDaa7JB"
       }}
  """

  @spec update(
          {:ok, %{client: Core.Client.t(), name: binary()}},
          list(),
          non_neg_integer(),
          non_neg_integer(),
          list()
        ) :: {:error, String.t()} | {:ok, map()}
  def update(
        {:ok, %{client: client, name: name}},
        pointers \\ [],
        name_ttl \\ 50_000,
        client_ttl \\ 86_000,
        opts \\ []
      ) do
    update_name(client, name, name_ttl, pointers, client_ttl, opts)
  end

  @doc """
  Updates a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_ttl = 49_999
      iex> pointers = []
      iex> client_ttl = 50_000
      iex> Core.AENS.update(client, name, name_ttl, pointers, client_ttl)
       {:ok,
        %{
          block_hash: "mh_KaN4zRfCqsm2pKKBq7NShMQWV2Mt3sL4VPEszc7ZwJb2s7CZZ",
          block_height: 74971,
          hash: "th_29YCfGGaarxy322azZrYuBDZAABWrMP1CuMsAFiUDoshzXkVjc",
          signatures: ["sg_GnAPiuQmNwwRBtY7zgoN3ihaFz5XH4KsjTzuJgViFyCkZVE3Qgvw56HfymZL4LvFxPWwmkGf3UvhzPmak1nFinFFn3yAG"],
          tx: %AeternityNode.Model.GenericTx{type: "NameUpdateTx", version: 1}
        }}
  """

  @spec update_name(
          Client.t(),
          String.t(),
          non_neg_integer(),
          list(),
          non_neg_integer(),
          list()
        ) :: {:error, String.t()} | {:ok, map()}
  def update_name(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        } = client,
        name,
        name_ttl,
        pointers,
        client_ttl,
        opts \\ []
      )
      when is_integer(name_ttl) and is_integer(client_ttl) and is_list(pointers) and
             sender_prefix == "ak" do
    with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
         {:ok, update_tx} <-
           build_update_tx(
             client,
             name_id,
             name_ttl,
             pointers,
             client_ttl,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, _} = response <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             update_tx,
             height
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameUpdateTx: #{inspect(error)}"}
    end
  end

  @spec transfer({:ok, %{client: Core.Client.t(), name: binary()}}, binary(), list()) ::
          {:error, String.t()} | {:ok, map()}
  def transfer({:ok, %{client: client, name: name}}, recipient_pub_key, opts \\ []) do
    transfer_name(client, name, recipient_pub_key, opts)
  end

  @doc """
  Transfers a name.

  ## Examples
      iex> name = "a123.test"
      iex> recipient_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
      iex> Core.AENS.transfer(client, name, recipient_key, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_mhmJEB3W8uQQsGzprNSZenC783FWAihP1miKW8qi3qDqkQAi9",
          block_height: 74934,
          hash: "th_XpwwJqW4S5oVLDRbgouPWo3nF1u8oon9KDmM944aKEJgr63az",
          signatures: ["sg_P6mPiWpa7yN3N2Q4ZuXMhxaJ1YruHHAfDZAQCBkyd4MM8peeffK3mEoZp4Wuote8ZmkLSCF3fzxdZLkE1BDz2SDXYu3CX"],
          tx: %AeternityNode.Model.GenericTx{type: "NameTransferTx", version: 1}
        }}
  """
  @spec transfer_name(Client.t(), String.t(), binary(), list()) ::
          {:error, String.t()} | {:ok, map()}
  def transfer_name(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        } = client,
        name,
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
        opts \\ []
      )
      when recipient_prefix == "ak" and sender_prefix == "ak" do
    with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
         {:ok, transfer_tx} <-
           build_transfer_tx(
             client,
             name_id,
             recipient_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             transfer_tx,
             height
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)
        |> Map.put(:recipient_id, recipient_id)

      {:ok, result}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameTransferTx: #{inspect(error)}"}
    end
  end

  @spec revoke({:ok, map()}, list()) :: {:error, String.t()} | {:ok, map()}
  def revoke({:ok, %{client: client, name: name}}, opts \\ []) do
    revoke_name(client, name, opts)
  end

  @doc """
  Revokes a name.

  ## Examples
      iex> name = "a123.test"
      iex> Core.AENS.revoke(client, name, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_2TeNu2CF1rjyCzk9FYqhBfBBH4LqfSvj3qx3hpKuPGrMUDGpXU",
          block_height: 74973,
          hash: "th_G4s1Befn1JLws54ZTSAxVidEqJ4vqVPaowzeqELf7u4DPfHks",
          signatures: ["sg_3kPx3pDu4CFDYZQdSQ2RrNU7wFuqcB2M83u8CxHXoRnN3xHQVgnpAmQvcbHT2ANpRCxvEKRA1r2JfA9rwkC9nDcnbQUve"],
          tx: %AeternityNode.Model.GenericTx{type: "NameRevokeTx", version: 1}
        }}
  """

  @spec revoke_name(Client.t(), String.t(), list()) :: {:error, String.t()} | {:ok, map()}
  def revoke_name(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        } = client,
        name,
        opts \\ []
      )
      when sender_prefix == "ak" do
    with {:ok, %NameEntry{id: name_id}} <- NameService.get_name_entry_by_name(connection, name),
         {:ok, revoke_tx} <-
           build_revoke_tx(
             client,
             name_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             revoke_tx,
             height
           ) do
      result =
        response
        |> Map.put(:client, client)
        |> Map.put(:name, name)

      {:ok, result}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameRevokeTx: #{inspect(error)}"}
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
         },
         commitment_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
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
         },
         name,
         name_salt,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection) do
      claim_tx =
        struct(
          NameClaimTx,
          account_id: sender_pubkey,
          nonce: nonce,
          name: name,
          name_salt: name_salt,
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
         },
         name_id,
         recipient_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
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
         },
         name_id,
         name_ttl,
         pointers,
         client_ttl,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
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
         },
         name_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
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
end
