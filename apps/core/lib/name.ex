defmodule Core.Name do
  alias AeternityNode.Model.{
    NamePreclaimTx,
    NameClaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx,
    InlineResponse2001,
    GenericSignedTx
  }

  alias AeternityNode.Api.Chain
  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.Transaction
  @prefix_byte_size 2

  @doc """
  Preclaims a name.

  ## Examples
      iex> name = "name.test"
      iex> name_salt = 7
      iex> {:ok, binary_commitment_hash} = Utils.Name.commitment_hash(name, name_salt)
      iex> commitment_hash = Utils.Encoding.prefix_encode_base58c("cm", binary_commitment_hash)
      iex> Core.Name.preclaim client, commitment_hash, [gas_price:  1_000_000_000_000]
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
           build_preclaim_tx_fields(
             client,
             commitment_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
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
      err -> {:error, "#{__MODULE__}: Unsuccessful post of NamePreclaimTx : #{inspect(err)}"}
    end
  end

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
           build_claim_tx_fields(
             client,
             name,
             name_salt,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
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
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameClaimTx"}
    end
  end

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
           build_transfer_tx_fields(
             client,
             name_id,
             recipient_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
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
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameTransferTx"}
    end
  end

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
           build_update_tx_fields(
             client,
             name_id,
             name_ttl,
             pointers,
             client_ttl,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
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
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameUpdateTx"}
    end
  end

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
           build_revoke_tx_fields(
             client,
             name_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
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
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameRevokeTx"}
    end
  end

  defp build_preclaim_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           network_id: network_id,
           connection: connection
         },
         commitment_id,
         fee,
         ttl,
         gas_price
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, preclaim_tx} <- create_preclaim_tx(commitment_id, fee, ttl, sender_pubkey, nonce),
         {:ok, %InlineResponse2001{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      fee =
        case gas_price do
          :minimum_protocol_gas_price ->
            Transaction.calculate_min_fee(preclaim_tx, height, network_id)

          gas_price when gas_price > 0 ->
            Transaction.min_gas(preclaim_tx, height) * gas_price
        end

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

  defp build_claim_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           network_id: network_id,
           connection: connection
         },
         name,
         name_salt,
         fee,
         ttl,
         gas_price
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, claim_tx} <- create_claim_tx(name, name_salt, fee, ttl, sender_pubkey, nonce),
         {:ok, %InlineResponse2001{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      fee =
        case gas_price do
          :minimum_protocol_gas_price ->
            Transaction.calculate_min_fee(claim_tx, height, network_id)

          gas_price when gas_price > 0 ->
            Transaction.min_gas(claim_tx, height) * gas_price
        end

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

  defp build_transfer_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           network_id: network_id,
           connection: connection
         },
         name_id,
         recipient_id,
         fee,
         ttl,
         gas_price
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, transfer_tx} <-
           create_transfer_tx(name_id, recipient_id, fee, ttl, sender_pubkey, nonce),
         {:ok, %InlineResponse2001{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      fee =
        case gas_price do
          :minimum_protocol_gas_price ->
            Transaction.calculate_min_fee(transfer_tx, height, network_id)

          gas_price when gas_price > 0 ->
            Transaction.min_gas(transfer_tx, height) * gas_price
        end

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

  defp build_update_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           network_id: network_id,
           connection: connection
         },
         name_id,
         name_ttl,
         pointers,
         client_ttl,
         fee,
         ttl,
         gas_price
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, update_tx} <-
           create_update_tx(
             name_id,
             name_ttl,
             pointers,
             client_ttl,
             fee,
             ttl,
             sender_pubkey,
             nonce
           ),
         {:ok, %InlineResponse2001{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      fee =
        case gas_price do
          :minimum_protocol_gas_price ->
            Transaction.calculate_min_fee(update_tx, height, network_id)

          gas_price when gas_price > 0 ->
            Transaction.min_gas(update_tx, height) * gas_price
        end

      {:ok,
       struct(NameUpdateTx,
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         pointers: pointers,
         client_ttl: client_ttl,
         fee: fee,
         ttl: ttl
       )}
    else
      {:error, _info} = error -> error
    end
  end

  defp build_revoke_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           network_id: network_id,
           connection: connection
         },
         name_id,
         fee,
         ttl,
         gas_price
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, revoke_tx} <-
           create_revoke_tx(
             name_id,
             fee,
             ttl,
             sender_pubkey,
             nonce
           ),
         {:ok, %InlineResponse2001{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      fee =
        case gas_price do
          :minimum_protocol_gas_price ->
            Transaction.calculate_min_fee(revoke_tx, height, network_id)

          gas_price when gas_price > 0 ->
            Transaction.min_gas(revoke_tx, height) * gas_price
        end

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

  defp create_preclaim_tx(
         commitment_id,
         fee,
         ttl,
         account_id,
         nonce
       ) do
    {:ok,
     %NamePreclaimTx{
       commitment_id: commitment_id,
       fee: fee,
       ttl: ttl,
       account_id: account_id,
       nonce: nonce
     }}
  end

  defp create_claim_tx(
         name,
         name_salt,
         fee,
         ttl,
         account_id,
         nonce
       ) do
    {:ok,
     %NameClaimTx{
       name: name,
       name_salt: name_salt,
       fee: fee,
       ttl: ttl,
       account_id: account_id,
       nonce: nonce
     }}
  end

  defp create_transfer_tx(
         name_id,
         recipient_id,
         fee,
         ttl,
         account_id,
         nonce
       ) do
    {:ok,
     %NameTransferTx{
       name_id: name_id,
       recipient_id: recipient_id,
       fee: fee,
       ttl: ttl,
       account_id: account_id,
       nonce: nonce
     }}
  end

  defp create_update_tx(
         name_id,
         name_ttl,
         pointers,
         client_ttl,
         fee,
         ttl,
         account_id,
         nonce
       ) do
    {:ok,
     %NameUpdateTx{
       name_id: name_id,
       name_ttl: name_ttl,
       pointers: pointers,
       client_ttl: client_ttl,
       fee: fee,
       ttl: ttl,
       account_id: account_id,
       nonce: nonce
     }}
  end

  defp create_revoke_tx(
         name_id,
         fee,
         ttl,
         account_id,
         nonce
       ) do
    {:ok,
     %NameRevokeTx{
       name_id: name_id,
       fee: fee,
       ttl: ttl,
       account_id: account_id,
       nonce: nonce
     }}
  end
end
