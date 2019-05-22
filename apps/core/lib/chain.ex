defmodule Core.Chain do
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Api.Debug, as: DebugApi
  alias AeternityNode.Api.NodeInfo, as: NodeInfoApi
  alias AeternityNode.Api.Transaction, as: TransactionApi
  alias AeternityNode.Model.InlineResponse2001, as: HeightResponse
  alias AeternityNode.Model.InlineResponse2003, as: PeerPubkeyResponse

  alias AeternityNode.Model.{
    ContractCallObject,
    DryRunInput,
    DryRunResults,
    Event,
    GenericTx,
    GenericTxs,
    GenericSignedTx,
    Generation,
    KeyBlock,
    MicroBlockHeader,
    Peers,
    PubKey,
    Status,
    Error
  }

  alias Utils.Transaction, as: TransactionUtils
  alias Core.Client
  alias Tesla.Env

  def height(%Client{connection: connection}) do
    case ChainApi.get_current_key_block_height(connection) do
      {:ok, %HeightResponse{height: height}} ->
        {:ok, height}

      {:error, %Env{}} = error ->
        error
    end
  end

  def await_height(%Client{} = client, height, opts \\ [])
      when is_integer(height) and height > 0 do
    await_attempts = Keyword.get(opts, :attempts, TransactionUtils.default_await_attempts())

    await_attempt_interval =
      Keyword.get(opts, :interval, TransactionUtils.default_await_attempt_interval())

    await_height(client, height, await_attempts, await_attempt_interval)
  end

  def await_transaction(%Client{connection: connection}, tx_hash, opts \\ []) do
    await_attempts = Keyword.get(opts, :attempts, TransactionUtils.default_await_attempts())

    await_attempt_interval =
      Keyword.get(opts, :interval, TransactionUtils.default_await_attempt_interval())

    await_tx(connection, tx_hash, await_attempts, await_attempt_interval)
  end

  def get_transaction(%Client{connection: connection}, tx_hash) do
    case TransactionApi.get_transaction_by_hash(connection, tx_hash) do
      {:ok,
       %GenericSignedTx{
         tx: %GenericTx{} = transaction
       } = signed_transaction} ->
        transaction_map = Map.from_struct(transaction)
        signed_transaction_map = Map.from_struct(signed_transaction)

        {:ok, %{signed_transaction_map | tx: transaction_map}}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_transaction_info(%Client{connection: connection}, tx_hash) do
    case TransactionApi.get_transaction_by_hash(connection, tx_hash) do
      {:ok,
       %ContractCallObject{
         log: logs
       } = transaction_info} ->
        logs =
          Enum.map(logs, fn log ->
            Map.from_struct(log)
          end)

        transaction_info_map = Map.from_struct(transaction_info)

        {:ok, %{transaction_info_map | log: logs}}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_pending_transactions(%Client{internal_connection: internal_connection}) do
    case TransactionApi.get_pending_transactions(internal_connection) do
      {:ok, %GenericTxs{transactions: transactions}} ->
        transactions =
          Enum.map(transactions, fn %GenericSignedTx{tx: %GenericTx{} = tx} = signed_tx ->
            tx_map = Map.from_struct(tx)
            signed_tx_map = Map.from_struct(signed_tx)

            %{signed_tx_map | tx: tx_map}
          end)

        {:ok, transactions}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_current_generation(%Client{connection: connection}) do
    case ChainApi.get_current_generation(connection) do
      {:ok, %Generation{key_block: %KeyBlock{} = key_block} = generation} ->
        key_block_map = Map.from_struct(key_block)
        generation_map = Map.from_struct(generation)

        {:ok, %{generation_map | key_block: key_block_map}}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_generation(%Client{connection: connection}, block_hash) when is_bitstring(block_hash) do
    case ChainApi.get_generation_by_hash(connection, block_hash) do
      {:ok, %Generation{key_block: %KeyBlock{} = key_block} = generation} ->
        key_block_map = Map.from_struct(key_block)
        generation_map = Map.from_struct(generation)

        {:ok, %{generation_map | key_block: key_block_map}}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_generation(%Client{connection: connection}, height) when is_integer(height) do
    case ChainApi.get_generation_by_height(connection, height) do
      {:ok, %Generation{key_block: %KeyBlock{} = key_block} = generation} ->
        key_block_map = Map.from_struct(key_block)
        generation_map = Map.from_struct(generation)

        {:ok, %{generation_map | key_block: key_block_map}}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_micro_block_transactions(%Client{connection: connection}, block_hash) do
    case ChainApi.get_micro_block_transactions_by_hash(connection, block_hash) do
      {:ok, %GenericTxs{transactions: transactions}} ->
        transactions =
          Enum.map(transactions, fn %GenericSignedTx{tx: %GenericTx{} = tx} = signed_tx ->
            tx_map = Map.from_struct(tx)
            signed_tx_map = Map.from_struct(signed_tx)

            %{signed_tx_map | tx: tx_map}
          end)

        {:ok, transactions}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_key_block(%Client{connection: connection}, block_hash) when is_bitstring(block_hash) do
    case ChainApi.get_key_block_by_hash(connection, block_hash) do
      {:ok, %KeyBlock{} = key_block} ->
        key_block_map = Map.from_struct(key_block)

        {:ok, key_block_map}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_key_block(%Client{connection: connection}, height) when is_integer(height) do
    case ChainApi.get_key_block_by_height(connection, height) do
      {:ok, %KeyBlock{} = key_block} ->
        key_block_map = Map.from_struct(key_block)

        {:ok, key_block_map}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_micro_block_header(%Client{connection: connection}, block_hash) do
    case ChainApi.get_micro_block_header_by_hash(connection, block_hash) do
      {:ok, %MicroBlockHeader{}} = response ->
        response

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def dry_run(
        %Client{internal_connection: internal_connection},
        transactions,
        accounts,
        block_hash
      ) do
    input = %DryRunInput{
      top: block_hash,
      accounts: accounts,
      txs: transactions
    }

    case DebugApi.dry_run_txs(internal_connection, input) do
      {:ok, %DryRunResults{results: results}} ->
        {:ok, results}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{}} = error ->
        error
    end
  end

  def get_info(%Client{connection: connection, internal_connection: internal_connection}) do
    with {:ok, %PeerPubkeyResponse{pubkey: peer_pubkey}} <-
           NodeInfoApi.get_peer_pubkey(connection),
         {:ok,
          %Status{
            genesis_key_block_hash: genesis_key_block_hash,
            solutions: solutions,
            difficulty: difficulty,
            syncing: syncing,
            sync_progress: sync_progress,
            listening: listening,
            protocols: protocols,
            node_version: node_version,
            node_revision: node_revision,
            peer_count: peer_count,
            pending_transactions_count: pending_transactions_count,
            network_id: network_id
          }} <- NodeInfoApi.get_status(connection),
         {:ok, %PubKey{pub_key: node_beneficiary}} <-
           NodeInfoApi.get_node_beneficiary(internal_connection),
         {:ok, %PubKey{pub_key: node_pubkey}} <- NodeInfoApi.get_node_pubkey(internal_connection),
         {:ok, %Peers{peers: peers, blocked: blocked}} <-
           NodeInfoApi.get_peers(internal_connection) do
      {:ok,
       %{
         peer_pubkey: peer_pubkey,
         status: %{
           genesis_key_block_hash: genesis_key_block_hash,
           solutions: solutions,
           difficulty: difficulty,
           syncing: syncing,
           sync_progress: sync_progress,
           listening: listening,
           protocols: protocols,
           node_version: node_version,
           node_revision: node_revision,
           peer_count: peer_count,
           pending_transactions_count: pending_transactions_count,
           network_id: network_id
         },
         node_beneficiary: node_beneficiary,
         node_pubkey: node_pubkey,
         peers: %{
           peers: peers,
           blocked: blocked
         }
       }}
    end
  end

  defp await_height(_client, height, 0, _interval),
    do: {:error, "Chain didn't reach height #{height}"}

  defp await_height(client, height, attempts, interval) do
    Process.sleep(interval)

    case height(client) do
      {:ok, ^height} ->
        :ok

      {:ok, current_height} when current_height > height ->
        :ok

      _ ->
        await_height(client, attempts - 1, interval)
    end
  end

  defp await_tx(_connection, tx_hash, 0, _interval),
    do: {:error, "Transaction #{tx_hash} wasn't mined"}

  defp await_tx(connection, tx_hash, attempts, interval) do
    case TransactionApi.get_transaction_by_hash(connection, tx_hash) do
      {:ok, %GenericSignedTx{block_hash: "none", block_height: -1}} ->
        await_tx(connection, tx_hash, attempts - 1, interval)

      {:ok, %GenericSignedTx{}} ->
        :ok

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}
    end
  end
end
