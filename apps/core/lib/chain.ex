defmodule Core.Chain do
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Api.Debug, as: DebugApi
  alias AeternityNode.Api.NodeInfo, as: NodeInfoApi
  alias AeternityNode.Api.Transaction, as: TransactionApi
  alias AeternityNode.Model.InlineResponse2001, as: HeightResponse
  alias AeternityNode.Model.InlineResponse2003, as: PeerPubkeyResponse

  alias AeternityNode.Model.{
    ContractCallObject,
    DryRunAccount,
    DryRunInput,
    DryRunResult,
    DryRunResults,
    Event,
    GenericTx,
    GenericTxs,
    GenericSignedTx,
    Generation,
    KeyBlock,
    MicroBlockHeader,
    Peers,
    Protocol,
    PubKey,
    Status,
    Error
  }

  alias Utils.Transaction, as: TransactionUtils
  alias Core.Client
  alias Tesla.Env

  @type generic_transaction :: %{version: non_neg_integer(), type: String.t()}
  @type generic_signed_transaction :: %{
          tx: generic_transaction(),
          block_height: non_neg_integer(),
          block_hash: String.t(),
          hash: String.t(),
          signatures: [String.t()]
        }
  @type event :: %{address: String.t(), topics: [non_neg_integer()], data: String.t()}
  @type transaction_info :: %{
          caller_id: String.t(),
          caller_nonce: non_neg_integer(),
          height: non_neg_integer(),
          contract_id: String.t(),
          gas_price: non_neg_integer(),
          gas_used: non_neg_integer(),
          log: [event()],
          return_value: String.t(),
          return_type: String.t()
        }
  @type key_block :: %{
          hash: String.t(),
          height: non_neg_integer(),
          prev_hash: String.t(),
          prev_key_hash: String.t(),
          state_hash: String.t(),
          miner: String.t(),
          beneficiary: String.t(),
          target: non_neg_integer(),
          pow: [non_neg_integer()] | nil,
          nonce: non_neg_integer() | nil,
          time: non_neg_integer(),
          version: non_neg_integer(),
          info: String.t()
        }
  @type generation :: %{
          key_block: key_block(),
          micro_blocks: [String.t()]
        }
  @type micro_block_header :: %{
          hash: String.t(),
          height: non_neg_integer(),
          pof_hash: String.t(),
          prev_hash: String.t(),
          prev_key_hash: String.t(),
          state_hash: String.t(),
          txs_hash: String.t(),
          signature: String.t(),
          time: non_neg_integer(),
          version: non_neg_integer()
        }
  @type dry_run_account :: %{pubkey: String.t(), amount: non_neg_integer()}
  @type dry_run_result :: %{
          type: String.t(),
          result: String.t(),
          reason: String.t() | nil,
          call_obj: transaction_info() | nil
        }
  @type protocol :: %{
          version: non_neg_integer(),
          effective_at_height: non_neg_integer()
        }
  @type status :: %{
          genesis_key_block_hash: String.t(),
          solutions: non_neg_integer(),
          difficulty: float(),
          syncing: boolean(),
          sync_progress: float() | nil,
          listening: boolean(),
          protocols: [protocol()],
          node_version: String.t(),
          node_revision: String.t(),
          peer_count: integer(),
          pending_transactions_count: non_neg_integer(),
          network_id: String.t()
        }
  @type peers :: %{
          peers: [String.t()],
          blocked: [String.t()]
        }
  @type info :: %{
          peer_pubkey: String.t() | nil,
          status: status(),
          node_beneficiary: String.t(),
          node_pubkey: String.t(),
          peers: peers()
        }

  @spec height(Client.t()) :: {:ok, non_neg_integer()} | {:error, Env.t()}
  def height(%Client{connection: connection}) do
    response = ChainApi.get_current_key_block_height(connection)

    prepare_result(response)
  end

  @spec await_height(Client.t(), non_neg_integer(), list()) ::
          :ok | {:error, String.t()} | {:error, Env.t()}
  def await_height(%Client{} = client, height, opts \\ [])
      when is_integer(height) and height > 0 do
    await_attempts = Keyword.get(opts, :attempts, TransactionUtils.default_await_attempts())

    await_attempt_interval =
      Keyword.get(opts, :interval, TransactionUtils.default_await_attempt_interval())

    await_height(client, height, await_attempts, await_attempt_interval)
  end

  @spec await_transaction(Client.t(), String.t(), list()) ::
          :ok | {:error, String.t()} | {:error, Env.t()}
  def await_transaction(%Client{connection: connection}, tx_hash, opts \\ [])
      when is_binary(tx_hash) do
    await_attempts = Keyword.get(opts, :attempts, TransactionUtils.default_await_attempts())

    await_attempt_interval =
      Keyword.get(opts, :interval, TransactionUtils.default_await_attempt_interval())

    await_tx(connection, tx_hash, await_attempts, await_attempt_interval)
  end

  @spec get_transaction(Client.t(), String.t()) ::
          {:ok, generic_signed_transaction()} | {:error, String.t()} | {:error, Env.t()}
  def get_transaction(%Client{connection: connection}, tx_hash) when is_binary(tx_hash) do
    response = TransactionApi.get_transaction_by_hash(connection, tx_hash)

    prepare_result(response)
  end

  @spec get_transaction_info(Client.t(), String.t()) ::
          {:ok, transaction_info()} | {:error, String.t()} | {:error, Env.t()}
  def get_transaction_info(%Client{connection: connection}, tx_hash) when is_binary(tx_hash) do
    response = TransactionApi.get_transaction_by_hash(connection, tx_hash)

    prepare_result(response)
  end

  @spec get_pending_transactions(Client.t()) ::
          {:ok, list(generic_signed_transaction())} | {:error, Env.t()}
  def get_pending_transactions(%Client{internal_connection: internal_connection}) do
    response = TransactionApi.get_pending_transactions(internal_connection)

    prepare_result(response)
  end

  @spec get_current_generation(Client.t()) ::
          {:ok, generation()} | {:error, String.t()} | {:error, Env.t()}
  def get_current_generation(%Client{connection: connection}) do
    response = ChainApi.get_current_generation(connection)

    prepare_result(response)
  end

  @spec get_generation(Client.t(), String.t()) ::
          {:ok, generation()} | {:error, String.t()} | {:error, Env.t()}
  def get_generation(%Client{connection: connection}, block_hash) when is_binary(block_hash) do
    response = ChainApi.get_generation_by_hash(connection, block_hash)

    prepare_result(response)
  end

  @spec get_generation(Client.t(), non_neg_integer()) ::
          {:ok, generation()} | {:error, String.t()} | {:error, Env.t()}
  def get_generation(%Client{connection: connection}, height) when is_integer(height) do
    response = ChainApi.get_generation_by_height(connection, height)

    prepare_result(response)
  end

  @spec get_micro_block_transactions(Client.t(), String.t()) ::
          {:ok, list(generic_signed_transaction())} | {:error, String.t()} | {:error, Env.t()}
  def get_micro_block_transactions(%Client{connection: connection}, block_hash)
      when is_binary(block_hash) do
    response = ChainApi.get_micro_block_transactions_by_hash(connection, block_hash)

    prepare_result(response)
  end

  @spec get_key_block(Client.t(), String.t()) ::
          {:ok, key_block()} | {:error, String.t()} | {:error, Env.t()}
  def get_key_block(%Client{connection: connection}, block_hash) when is_binary(block_hash) do
    response = ChainApi.get_key_block_by_hash(connection, block_hash)

    prepare_result(response)
  end

  @spec get_key_block(Client.t(), non_neg_integer()) ::
          {:ok, key_block()} | {:error, String.t()} | {:error, Env.t()}
  def get_key_block(%Client{connection: connection}, height) when is_integer(height) do
    response = ChainApi.get_key_block_by_height(connection, height)

    prepare_result(response)
  end

  @spec get_micro_block_header(Client.t(), String.t()) ::
          {:ok, micro_block_header()} | {:error, String.t()} | {:error, Env.t()}
  def get_micro_block_header(%Client{connection: connection}, block_hash)
      when is_binary(block_hash) do
    response = ChainApi.get_micro_block_header_by_hash(connection, block_hash)

    prepare_result(response)
  end

  @spec dry_run(Client.t(), list(String.t()), list(dry_run_account()), String.t()) ::
          {:ok, list(dry_run_result())} | {:error, String.t()} | {:error, Env.t()}
  def dry_run(
        %Client{internal_connection: internal_connection},
        transactions,
        accounts,
        block_hash
      )
      when is_list(transactions) and is_list(accounts) and is_binary(block_hash) do
    dry_run_accounts =
      Enum.map(accounts, fn %{pubkey: pubkey, amount: amount} ->
        %DryRunAccount{pub_key: pubkey, amount: amount}
      end)

    input = %DryRunInput{
      top: block_hash,
      accounts: dry_run_accounts,
      txs: transactions
    }

    response = DebugApi.dry_run_txs(internal_connection, input)

    prepare_result(response)
  end

  @spec get_info(Client.t()) :: {:ok, info()} | {:error, String.t()} | {:error, Env.t()}
  def get_info(%Client{connection: connection, internal_connection: internal_connection}) do
    with {:ok, %PeerPubkeyResponse{pubkey: peer_pubkey}} <-
           NodeInfoApi.get_peer_pubkey(connection),
         {:ok, %Status{} = status} <- NodeInfoApi.get_status(connection),
         {:ok, %PubKey{pub_key: node_beneficiary}} <-
           NodeInfoApi.get_node_beneficiary(internal_connection),
         {:ok, %PubKey{pub_key: node_pubkey}} <- NodeInfoApi.get_node_pubkey(internal_connection),
         {:ok, %Peers{} = peers} <-
           NodeInfoApi.get_peers(internal_connection) do
      {:ok,
       %{
         peer_pubkey: peer_pubkey,
         status: struct_to_map_recursive(status),
         node_beneficiary: node_beneficiary,
         node_pubkey: node_pubkey,
         peers: Map.from_struct(peers)
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

  defp prepare_result({:ok, %HeightResponse{height: height}}) do
    {:ok, height}
  end

  defp prepare_result({:ok, %GenericSignedTx{} = generic_signed_transaction}) do
    {:ok, struct_to_map_recursive(generic_signed_transaction)}
  end

  defp prepare_result({:ok, %ContractCallObject{} = transaction_info}) do
    {:ok, struct_to_map_recursive(transaction_info)}
  end

  defp prepare_result({:ok, %GenericTxs{transactions: transactions}}) do
    transactions =
      Enum.map(transactions, fn generic_signed_transaction ->
        struct_to_map_recursive(generic_signed_transaction)
      end)

    {:ok, transactions}
  end

  defp prepare_result({:ok, %Generation{} = generation}) do
    {:ok, struct_to_map_recursive(generation)}
  end

  defp prepare_result({:ok, %KeyBlock{} = key_block}) do
    {:ok, Map.from_struct(key_block)}
  end

  defp prepare_result({:ok, %MicroBlockHeader{} = micro_block_header}) do
    {:ok, Map.from_struct(micro_block_header)}
  end

  defp prepare_result({:ok, %DryRunResults{results: results}}) do
    results =
      Enum.map(
        results,
        fn dry_run_result ->
          struct_to_map_recursive(dry_run_result)
        end
      )

    {:ok, results}
  end

  defp prepare_result({:ok, %Error{reason: message}}) do
    {:error, message}
  end

  defp prepare_result({:error, %Env{}} = error) do
    error
  end

  defp struct_to_map_recursive(
         %GenericSignedTx{
           tx: %GenericTx{} = generic_transaction
         } = generic_signed_transaction
       ) do
    generic_transaction_map = Map.from_struct(generic_transaction)
    generic_signed_transaction_map = Map.from_struct(generic_signed_transaction)

    %{generic_signed_transaction_map | tx: generic_transaction_map}
  end

  defp struct_to_map_recursive(
         %ContractCallObject{
           log: log
         } = contract_call_object
       ) do
    log =
      Enum.map(log, fn %Event{} = event ->
        Map.from_struct(event)
      end)

    contract_call_object_map = Map.from_struct(contract_call_object)

    %{contract_call_object_map | log: log}
  end

  defp struct_to_map_recursive(%Generation{key_block: %KeyBlock{} = key_block} = generation) do
    key_block_map = Map.from_struct(key_block)
    generation_map = Map.from_struct(generation)

    %{generation_map | key_block: key_block_map}
  end

  defp struct_to_map_recursive(
         %DryRunResult{call_obj: %ContractCallObject{} = contract_call_object} = dry_run_result
       ) do
    contract_call_object_map = struct_to_map_recursive(contract_call_object)
    dry_run_result_map = Map.from_struct(dry_run_result)

    %{dry_run_result_map | call_obj: contract_call_object_map}
  end

  defp struct_to_map_recursive(%Status{protocols: protocols} = status) do
    protocols =
      Enum.map(protocols, fn %Protocol{} = protocol ->
        Map.from_struct(protocol)
      end)

    status_map = Map.from_struct(status)

    %{status_map | protocols: protocols}
  end
end
