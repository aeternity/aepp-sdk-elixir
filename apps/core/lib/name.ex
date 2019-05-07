defmodule Core.Name do
  @moduledoc """
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
    GenericSignedTx,
    CommitmentId,
    NameEntry
  }

  alias AeternityNode.Api.NameService
  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.Transaction

  @prefix_byte_size 2

  @doc """
  Preclaims a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_salt = 7
      iex> commitment_id = Core.Name.commitment_id(client, name, name_salt)
      iex> Core.Name.preclaim(client, commitment_id, [fee:  1_000_000_000_000_000])
      {:ok,
       %{
         block_hash: "mh_2aBYJJkAKWUrLgfuYMtzuwe664qcJmKTg9nZbJKJqCZCP45qXx",
         block_height: 74520,
         hash: "th_2sSWCChUievTNvuuZXUGr3EdKmGdDiH3GVd9au7eaTYdTSFh85",
         signatures: ["sg_CUjN52PbibG2US2KYowbkjqEvGauPie1rqcGPagFJ9CfnzCVrFTxaedRQpyqr1zvT9oGu9WP6hqZaVp7nDW1mzcuyEqPF"],
         tx: %AeternityNode.Model.GenericTx{type: "NamePreclaimTx", version: 1}
       }}
  """
  @spec preclaim(Core.Client.t(), binary(), list()) ::
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
        <<commitment_prefix::binary-size(@prefix_byte_size), _::binary>> = commitment_id,
        opts \\ []
      )
      when sender_prefix == "ak" and commitment_prefix == "cm" do
    with {:ok, preclaim_tx} <-
           build_preclaim_tx(
             client,
             commitment_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %GenericSignedTx{} = tx} <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             preclaim_tx
           ) do
      {:ok, Map.from_struct(tx)}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NamePreclaimTx : #{inspect(error)}"}
    end
  end

  @doc """
  Claims a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_salt = 7
      iex> Core.Name.claim(client, name, name_salt, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_7UU32yA7UFYKUXUeacuywogKgheJBmNrKCDRRXb6vqCzMrism",
          block_height: 74932,
          hash: "th_bRhCGSguVScR4V8KKjKiaaJPbvKthFZSB7nP2DLggyStcpQjQ",
          signatures: ["sg_a4eaiajvEoh1ZC6cuHJLzXtfvRiVJwbnzLP5qpA8KYEgEZt6VxgXR8ZjcZGpoDDyYq5cH3LXkLDXRS4vqfu2BVEdChGJa"],
          tx: %AeternityNode.Model.GenericTx{type: "NameClaimTx", version: 1}
      }}
  """
  @spec claim(Core.Client.t(), String.t(), integer(), list()) ::
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
         {:ok, %GenericSignedTx{} = tx} <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             claim_tx
           ) do
      {:ok, Map.from_struct(tx)}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameClaimTx: #{inspect(error)} "}
    end
  end

  @doc """
  Updates a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_id = Utils.Name.get_name_id_by_name(client, name)
      iex> name_ttl = 49_999
      iex> pointers = []
      iex> client_ttl = 50_000
      iex> Core.Name.update(client, name_id, name_ttl, pointers, client_ttl, [fee:  1_000_000_000_000_000])
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
          Core.Client.t(),
          binary(),
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
        <<name_prefix::binary-size(@prefix_byte_size), _::binary>> = name_id,
        name_ttl,
        pointers,
        client_ttl,
        opts \\ []
      )
      when is_integer(name_ttl) and name_prefix == "nm" and is_integer(client_ttl) and
             is_list(pointers) and sender_prefix == "ak" do
    with {:ok, update_tx} <-
           build_update_tx(
             client,
             name_id,
             name_ttl,
             pointers,
             client_ttl,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %GenericSignedTx{} = tx} <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             update_tx
           ) do
      {:ok, Map.from_struct(tx)}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameUpdateTx: #{inspect(error)}"}
    end
  end

  @doc """
  Transfers a name.

  ## Examples
      iex> name = "a123.test"
      iex> name_id = Utils.Name.get_name_id_by_name(client, name)
      iex> recipient_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
      iex> Core.Name.transfer(client, name_id, recipient_key, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_mhmJEB3W8uQQsGzprNSZenC783FWAihP1miKW8qi3qDqkQAi9",
          block_height: 74934,
          hash: "th_XpwwJqW4S5oVLDRbgouPWo3nF1u8oon9KDmM944aKEJgr63az",
          signatures: ["sg_P6mPiWpa7yN3N2Q4ZuXMhxaJ1YruHHAfDZAQCBkyd4MM8peeffK3mEoZp4Wuote8ZmkLSCF3fzxdZLkE1BDz2SDXYu3CX"],
          tx: %AeternityNode.Model.GenericTx{type: "NameTransferTx", version: 1}
        }}
  """
  @spec transfer(Core.Client.t(), binary(), binary(), list()) ::
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
        <<name_prefix::binary-size(@prefix_byte_size), _::binary>> = name_id,
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
        opts \\ []
      )
      when name_prefix == "nm" and recipient_prefix == "ak" and sender_prefix == "ak" do
    with {:ok, transfer_tx} <-
           build_transfer_tx(
             client,
             name_id,
             recipient_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %GenericSignedTx{} = tx} <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             transfer_tx
           ) do
      {:ok, Map.from_struct(tx)}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameTransferTx: #{inspect(error)}"}
    end
  end

  @doc """
  Revokes a name.

  ## Examples
      iex> name_id = Utils.Name.get_name_id_by_name(client, "a123.test")
      iex> Core.Name.revoke(client, name_id, [fee:  1_000_000_000_000_000])
       {:ok,
        %{
          block_hash: "mh_2TeNu2CF1rjyCzk9FYqhBfBBH4LqfSvj3qx3hpKuPGrMUDGpXU",
          block_height: 74973,
          hash: "th_G4s1Befn1JLws54ZTSAxVidEqJ4vqVPaowzeqELf7u4DPfHks",
          signatures: ["sg_3kPx3pDu4CFDYZQdSQ2RrNU7wFuqcB2M83u8CxHXoRnN3xHQVgnpAmQvcbHT2ANpRCxvEKRA1r2JfA9rwkC9nDcnbQUve"],
          tx: %AeternityNode.Model.GenericTx{type: "NameRevokeTx", version: 1}
        }}
  """
  @spec revoke(Core.Client.t(), binary(), list()) :: {:error, String.t()} | {:ok, map()}
  def revoke(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
        } = client,
        <<name_prefix::binary-size(@prefix_byte_size), _::binary>> = name_id,
        opts \\ []
      )
      when sender_prefix == "ak" and name_prefix == "nm" do
    with {:ok, revoke_tx} <-
           build_revoke_tx(
             client,
             name_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl())
           ),
         {:ok, %GenericSignedTx{} = tx} <-
           Transaction.post(
             connection,
             privkey,
             network_id,
             revoke_tx
           ) do
      {:ok, Map.from_struct(tx)}
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of NameRevokeTx: #{inspect(error)}"}
    end
  end

  @doc """
  Creates name commitment hash .

  ## Examples
      iex> Core.Name.commitment_id(client, "a123.test", 7)
      "cm_2rxmhXWBzjsXTsLfxYK5dqGxKzcJphSijJ3TVHe23mVWYJZhTY"
  """
  @spec commitment_id(Client.t(), String.t(), integer()) :: String.t() | {:error, String.t()}
  def commitment_id(%Client{connection: connection}, name, name_salt)
      when is_binary(name) and is_integer(name_salt) do
    case NameService.get_commitment_id(connection, name, name_salt) do
      {:ok, %CommitmentId{commitment_id: commitment_id}} -> commitment_id
      error -> error
    end
  end

  @doc """
  Lookups the information about the given name.

  ## Examples
      iex> Core.Name.get_name_id_by_name(client, "a123.test")
      {:ok, %AeternityNode.Model.Error{reason: "Name revoked"}}
  """
  @spec get_name_id_by_name(Client.t(), String.t()) :: String.t() | {:error, String.t()}
  def get_name_id_by_name(%Client{connection: connection}, name) when is_binary(name) do
    case NameService.get_name_entry_by_name(connection, name) do
      {:ok, %NameEntry{id: id}} -> id
      error -> error
    end
  end

  defp build_preclaim_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection
         },
         commitment_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey) do
      {:ok,
       struct(NamePreclaimTx,
         account_id: sender_pubkey,
         nonce: nonce,
         commitment_id: commitment_id,
         fee: fee,
         ttl: ttl
       )}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_claim_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection
         },
         name,
         name_salt,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey) do
      {:ok,
       struct(NameClaimTx,
         account_id: sender_pubkey,
         nonce: nonce,
         name: name,
         name_salt: name_salt,
         fee: fee,
         ttl: ttl
       )}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_transfer_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection
         },
         name_id,
         recipient_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey) do
      {:ok,
       struct(NameTransferTx,
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         recipient_id: recipient_id,
         fee: fee,
         ttl: ttl
       )}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_update_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection
         },
         name_id,
         name_ttl,
         pointers,
         client_ttl,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey) do
      {:ok,
       struct(NameUpdateTx,
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         pointers: pointers,
         name_ttl: name_ttl,
         client_ttl: client_ttl,
         fee: fee,
         ttl: ttl
       )}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_revoke_tx(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection
         },
         name_id,
         fee,
         ttl
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey) do
      {:ok,
       struct(NameRevokeTx,
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         fee: fee,
         ttl: ttl
       )}
    else
      {:error, _info} = error -> error
    end
  end
end
