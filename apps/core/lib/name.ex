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
      iex> Core.AENS.preclaim(client, name, name_salt, [fee:  1_000_000_000_000_000])
      {:ok,
       %{
         block_hash: "mh_2aBYJJkAKWUrLgfuYMtzuwe664qcJmKTg9nZbJKJqCZCP45qXx",
         block_height: 74520,
         hash: "th_2sSWCChUievTNvuuZXUGr3EdKmGdDiH3GVd9au7eaTYdTSFh85",
         signatures: ["sg_CUjN52PbibG2US2KYowbkjqEvGauPie1rqcGPagFJ9CfnzCVrFTxaedRQpyqr1zvT9oGu9WP6hqZaVp7nDW1mzcuyEqPF"],
         tx: %AeternityNode.Model.GenericTx{type: "NamePreclaimTx", version: 1}
       }}
  """
  @spec preclaim(Client.t(), String.t(), non_neg_integer(), list()) ::
          {:error, String.t()} | {:ok, map()}
  def preclaim(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
        } = client,
        name,
        name_salt,
        opts \\ []
      )
      when sender_prefix == "ak" do
    with {:ok, %CommitmentId{commitment_id: commitment_id}} <-
           NameService.get_commitment_id(connection, name, name_salt),
         {:ok, preclaim_tx} <-
           build_preclaim_tx(
             client,
             commitment_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, _tx} = response <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             preclaim_tx
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NamePreclaimTx : #{inspect(error)}"}
    end
  end

  @doc """
  Claims a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_salt = 7
      iex> Core.AENS.claim(client, name, name_salt, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_7UU32yA7UFYKUXUeacuywogKgheJBmNrKCDRRXb6vqCzMrism",
          block_height: 74932,
          hash: "th_bRhCGSguVScR4V8KKjKiaaJPbvKthFZSB7nP2DLggyStcpQjQ",
          signatures: ["sg_a4eaiajvEoh1ZC6cuHJLzXtfvRiVJwbnzLP5qpA8KYEgEZt6VxgXR8ZjcZGpoDDyYq5cH3LXkLDXRS4vqfu2BVEdChGJa"],
          tx: %AeternityNode.Model.GenericTx{type: "NameClaimTx", version: 1}
      }}
  """
  @spec claim(Client.t(), String.t(), integer(), list()) ::
          {:error, String.t()} | {:ok, map()}
  def claim(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
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
         {:ok, _tx} = response <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             claim_tx
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameClaimTx: #{inspect(error)} "}
    end
  end

  @doc """
  Updates a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_ttl = 49_999
      iex> pointers = []
      iex> client_ttl = 50_000
      iex> Core.AENS.update(client, name, name_ttl, pointers, client_ttl, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_KaN4zRfCqsm2pKKBq7NShMQWV2Mt3sL4VPEszc7ZwJb2s7CZZ",
          block_height: 74971,
          hash: "th_29YCfGGaarxy322azZrYuBDZAABWrMP1CuMsAFiUDoshzXkVjc",
          signatures: ["sg_GnAPiuQmNwwRBtY7zgoN3ihaFz5XH4KsjTzuJgViFyCkZVE3Qgvw56HfymZL4LvFxPWwmkGf3UvhzPmak1nFinFFn3yAG"],
          tx: %AeternityNode.Model.GenericTx{type: "NameUpdateTx", version: 1}
        }}
  """

  @spec update(
          Client.t(),
          String.t(),
          integer(),
          list(),
          integer(),
          list()
        ) :: {:error, String.t()} | {:ok, map()}
  def update(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
        } = client,
        name,
        name_ttl,
        pointers,
        client_ttl,
        opts \\ []
      )
      when is_integer(name_ttl) and is_integer(client_ttl) and
             is_list(pointers) and sender_prefix == "ak" do
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
         {:ok, _tx} = response <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             update_tx
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameUpdateTx: #{inspect(error)}"}
    end
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
  @spec transfer(Client.t(), String.t(), binary(), list()) ::
          {:error, String.t()} | {:ok, map()}
  def transfer(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
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
         {:ok, _tx} = response <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             transfer_tx
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameTransferTx: #{inspect(error)}"}
    end
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
  @spec revoke(Client.t(), String.t(), list()) :: {:error, String.t()} | {:ok, map()}
  def revoke(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
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
         {:ok, _tx} = response <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             revoke_tx
           ) do
      response
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
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      preclaim_tx =
        struct(NamePreclaimTx,
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
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      claim_tx =
        struct(NameClaimTx,
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
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      transfer_tx =
        struct(NameTransferTx,
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
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      name_update_tx =
        struct(NameUpdateTx,
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
         {:ok, %{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      revoke_tx =
        struct(NameRevokeTx,
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
