defmodule Core.Name do
  alias AeternityNode.Model.{
    NamePreclaimTx,
    NameClaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx,
    InlineResponse2001
  }

  alias AeternityNode.Api.Chain
  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias Utils.Transaction
  @prefix_byte_size 2

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
    with {:ok, preclaim_tx_fields} <-
           build_preclaim_tx_fields(
             client,
             commitment_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
           ) do
      Transaction.post(
        connection,
        privkey,
        network_id,
        struct(NamePreclaimTx, preclaim_tx_fields)
      )
    else
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NamePreclaimTx"}
    end
  end

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
    with {:ok, claim_tx_fields} <-
           build_claim_tx_fields(
             client,
             name,
             name_salt,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
           ) do
      Transaction.post(
        connection,
        privkey,
        network_id,
        struct(NameClaimTx, claim_tx_fields)
      )
    else
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameClaimTx"}
    end
  end

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
    with {:ok, transfer_tx_fields} <-
           build_transfer_tx_fields(
             client,
             name_id,
             recipient_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
           ) do
      Transaction.post(
        connection,
        privkey,
        network_id,
        struct(NameTransferTx, transfer_tx_fields)
      )
    else
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameTransferTx"}
    end
  end

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
    with {:ok, update_tx_fields} <-
           build_update_tx_fields(
             client,
             name_id,
             name_ttl,
             pointers,
             client_ttl,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
           ) do
      Transaction.post(
        connection,
        privkey,
        network_id,
        struct(NameUpdateTx, update_tx_fields)
      )
    else
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of NameUpdateTx"}
    end
  end

  def revoke(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
        } = client,
        name_id,
        opts \\ []
      )
      when sender_prefix == "ak" do
    with {:ok, revoke_tx_fields} <-
           build_revoke_tx_fields(
             client,
             name_id,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
           ) do
      Transaction.post(
        connection,
        privkey,
        network_id,
        struct(NameRevokeTx, revoke_tx_fields)
      )
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
       [
         account_id: sender_pubkey,
         nonce: nonce,
         commitment_id: commitment_id,
         fee: fee,
         ttl: ttl
       ]}
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
       [
         account_id: sender_pubkey,
         nonce: nonce,
         name: name,
         name_salt: name_salt,
         fee: fee,
         ttl: ttl
       ]}
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
       [
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         recipient_id: recipient_id,
         fee: fee,
         ttl: ttl
       ]}
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
       [
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         pointers: pointers,
         client_ttl: client_ttl,
         fee: fee,
         ttl: ttl
       ]}
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
       [
         account_id: sender_pubkey,
         nonce: nonce,
         name_id: name_id,
         fee: fee,
         ttl: ttl
       ]}
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
