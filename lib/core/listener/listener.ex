defmodule Core.Listener do
  use GenServer

  alias Core.Listener.Supervisor

  @gc_objects_sent_interval 180_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start(network_id) when network_id in ["ae_mainnet", "ae_uat"],
    do: Supervisor.start_link(%{network: network_id, initial_peers: [], genesis: nil})

  def start(_),
    do:
      {:error,
       "Cannot start Listener for a non-predefined network, use start/3 for private networks"}

  def start(peers, network_id, genesis_hash)
      when is_list(peers) and is_binary(network_id) and is_binary(genesis_hash),
      do:
        Supervisor.start_link(%{initial_peers: peers, network: network_id, genesis: genesis_hash})

  def init(_) do
    do_gc_objects_sent()

    {:ok,
     %{
       objects_sent: %{},
       micro_block_subscribers: [],
       key_block_subscribers: [],
       txs_subscribers: [],
       pool_txs_subscribers: [],
       spend_transaction_subscribers: [],
       oracle_query_subscribers: [],
       oracle_response_subscribers: []
     }}
  end

  def subscribe_for_micro_blocks(subscriber_pid),
    do: GenServer.call(__MODULE__, {:subscribe_for_micro_blocks, subscriber_pid})

  def unsubscribe_from_micro_blocks(subscriber_pid),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_micro_blocks, subscriber_pid})

  def subscribe_for_key_blocks(subscriber_pid),
    do: GenServer.call(__MODULE__, {:subscribe_for_key_blocks, subscriber_pid})

  def unsubscribe_from_key_blocks(subscriber_pid),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_key_blocks, subscriber_pid})

  def subscribe_for_txs(subscriber_pid),
    do: GenServer.call(__MODULE__, {:subscribe_for_txs, subscriber_pid})

  def unsubscribe_from_txs(subscriber_pid),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_txs, subscriber_pid})

  def subscribe_for_pool_txs(subscriber_pid),
    do: GenServer.call(__MODULE__, {:subscribe_for_pool_txs, subscriber_pid})

  def unsubscribe_from_pool_txs(subscriber_pid),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_pool_txs, subscriber_pid})

  def subscribe_for_spend_transactions(subscriber_pid, pubkey),
    do: GenServer.call(__MODULE__, {:subscribe_for_spend_transactions, subscriber_pid, pubkey})

  def unsubscribe_from_spend_transactions(subscriber_pid, pubkey),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_spend_transactions, subscriber_pid, pubkey})

  def subscribe_for_oracle_queries(subscriber_pid, oracle_id),
    do: GenServer.call(__MODULE__, {:subscribe_for_oracle_queries, subscriber_pid, oracle_id})

  def unsubscribe_from_oracle_queries(subscriber_pid, oracle_id),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_oracle_queries, subscriber_pid, oracle_id})

  def subscribe_for_oracle_response(subscriber_pid, query_id),
    do: GenServer.call(__MODULE__, {:subscribe_for_oracle_response, subscriber_pid, query_id})

  def unsubscribe_from_oracle_response(subscriber_pid, query_id),
    do: GenServer.call(__MODULE__, {:unsubscribe_from_oracle_response, subscriber_pid, query_id})

  def notify_for_micro_block(micro_block, hash),
    do: GenServer.cast(__MODULE__, {:notify_for_micro_block, micro_block, hash})

  def notify_for_key_block(key_block, hash),
    do: GenServer.cast(__MODULE__, {:notify_for_key_block, key_block, hash})

  def notify_for_txs(txs, hash), do: GenServer.cast(__MODULE__, {:notify_for_txs, txs, hash})

  def notify_for_pool_txs(txs, hash),
    do: GenServer.cast(__MODULE__, {:notify_for_pool_txs, txs, hash})

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_call(
        {:subscribe_for_micro_blocks, subscriber_pid},
        _from,
        %{micro_block_subscribers: micro_block_subscribers} = state
      ) do
    {:reply, :ok,
     %{state | micro_block_subscribers: add_subscriber(subscriber_pid, micro_block_subscribers)}}
  end

  def handle_call(
        {:unsubscribe_from_micro_blocks, subscriber_pid},
        _from,
        %{micro_block_subscribers: micro_block_subscribers} = state
      ) do
    {:reply, :ok,
     %{state | micro_block_subscribers: List.delete(micro_block_subscribers, subscriber_pid)}}
  end

  def handle_call(
        {:subscribe_for_key_blocks, subscriber_pid},
        _from,
        %{key_block_subscribers: key_block_subscribers} = state
      ) do
    {:reply, :ok,
     %{state | key_block_subscribers: add_subscriber(subscriber_pid, key_block_subscribers)}}
  end

  def handle_call(
        {:unsubscribe_from_key_blocks, subscriber_pid},
        _from,
        %{key_block_subscribers: key_block_subscribers} = state
      ) do
    {:reply, :ok,
     %{state | key_block_subscribers: List.delete(key_block_subscribers, subscriber_pid)}}
  end

  def handle_call(
        {:subscribe_for_txs, subscriber_pid},
        _from,
        %{txs_subscribers: txs_subscribers} = state
      ) do
    {:reply, :ok, %{state | txs_subscribers: add_subscriber(subscriber_pid, txs_subscribers)}}
  end

  def handle_call(
        {:unsubscribe_from_txs, subscriber_pid},
        _from,
        %{txs_subscribers: txs_subscribers} = state
      ) do
    {:reply, :ok, %{state | txs_subscribers: List.delete(txs_subscribers, subscriber_pid)}}
  end

  def handle_call(
        {:subscribe_for_pool_txs, subscriber_pid},
        _from,
        %{txs_subscribers: txs_subscribers} = state
      ) do
    {:reply, :ok,
     %{state | pool_txs_subscribers: add_subscriber(subscriber_pid, txs_subscribers)}}
  end

  def handle_call(
        {:unsubscribe_from_pool_txs, subscriber_pid},
        _from,
        %{txs_subscribers: txs_subscribers} = state
      ) do
    {:reply, :ok, %{state | pool_txs_subscribers: List.delete(txs_subscribers, subscriber_pid)}}
  end

  def handle_call(
        {:subscribe_for_spend_transactions, subscriber_pid, pubkey},
        _from,
        %{
          spend_transaction_subscribers: spend_transaction_subscribers
        } = state
      ) do
    {:reply, :ok,
     %{
       state
       | spend_transaction_subscribers:
           add_subscriber(
             %{subscriber: subscriber_pid, pubkey: pubkey},
             spend_transaction_subscribers
           )
     }}
  end

  def handle_call(
        {:unsubscribe_from_spend_transactions, subscriber_pid, pubkey},
        _from,
        %{spend_transaction_subscribers: spend_transaction_subscribers} = state
      ) do
    {:reply, :ok,
     %{
       state
       | spend_transaction_subscribers:
           List.delete(spend_transaction_subscribers, %{
             subscriber: subscriber_pid,
             pubkey: pubkey
           })
     }}
  end

  def handle_call(
        {:subscribe_for_oracle_queries, subscriber_pid, oracle_id},
        _from,
        %{oracle_query_subscribers: oracle_query_subscribers} = state
      ) do
    {:reply, :ok,
     %{
       state
       | oracle_query_subscribers:
           add_subscriber(
             %{subscriber: subscriber_pid, oracle_id: oracle_id},
             oracle_query_subscribers
           )
     }}
  end

  def handle_call(
        {:unsubscribe_from_oracle_queries, subscriber_pid, oracle_id},
        _from,
        %{oracle_query_subscribers: oracle_query_subscribers} = state
      ) do
    {:reply, :ok,
     %{
       state
       | oracle_query_subscribers:
           List.delete(oracle_query_subscribers, %{
             subscriber: subscriber_pid,
             oracle_id: oracle_id
           })
     }}
  end

  def handle_call(
        {:subscribe_for_oracle_response, subscriber_pid, query_id},
        _from,
        %{
          oracle_response_subscribers: oracle_response_subscribers
        } = state
      ) do
    {:reply, :ok,
     %{
       state
       | oracle_response_subscribers:
           add_subscriber(
             %{subscriber: subscriber_pid, query_id: query_id},
             oracle_response_subscribers
           )
     }}
  end

  def handle_call(
        {:unsubscribe_from_oracle_response, subscriber_pid, query_id},
        _from,
        %{oracle_response_subscribers: oracle_response_subscribers} = state
      ) do
    {:reply, :ok,
     %{
       state
       | oracle_response_subscribers:
           List.delete(oracle_response_subscribers, %{
             subscriber: subscriber_pid,
             query_id: query_id
           })
     }}
  end

  def handle_cast(
        {:notify_for_micro_block, micro_block, hash},
        %{
          objects_sent: objects_sent,
          micro_block_subscribers: micro_block_subscribers
        } = state
      ) do
    updated_objects_sent =
      send_object_to_subscribers(
        :micro_block,
        micro_block,
        hash,
        micro_block_subscribers,
        objects_sent
      )

    {:noreply, %{state | objects_sent: updated_objects_sent}}
  end

  def handle_cast(
        {:notify_for_key_block, key_block, hash},
        %{
          objects_sent: objects_sent,
          key_block_subscribers: key_block_subscribers
        } = state
      ) do
    updated_objects_sent =
      send_object_to_subscribers(:key_block, key_block, hash, key_block_subscribers, objects_sent)

    {:noreply, %{state | objects_sent: updated_objects_sent}}
  end

  def handle_cast(
        {:notify_for_txs, txs, hash},
        %{
          objects_sent: objects_sent,
          txs_subscribers: txs_subscribers
        } = state
      ) do
    updated_objects_sent =
      send_object_to_subscribers(:txs, txs, hash, txs_subscribers, objects_sent)

    {:noreply, %{state | objects_sent: updated_objects_sent}}
  end

  def handle_cast(
        {:notify_for_pool_txs, txs, hash},
        %{
          objects_sent: objects_sent,
          pool_txs_subscribers: pool_txs_subscribers
        } = state
      ) do
    updated_objects_sent =
      send_object_to_subscribers(:pool_txs, txs, hash, pool_txs_subscribers, objects_sent)

    {:noreply, %{state | objects_sent: updated_objects_sent}}
  end

  def handle_info(:gc_objects_sent, state) do
    do_gc_objects_sent()
    {:noreply, %{state | objects_sent: %{}}}
  end

  defp add_subscriber(subscriber, subscribers) do
    if Enum.member?(subscribers, subscriber) do
      subscribers
    else
      [subscriber | subscribers]
    end
  end

  defp send_object_to_subscribers(type, object, hash, subscribers, objects_sent) do
    Enum.reduce(subscribers, objects_sent, fn subscriber, acc ->
      object_receivers = Map.get(objects_sent, hash, [])

      if Enum.member?(object_receivers, subscriber) do
        acc
      else
        send(subscriber, {type, object})

        Map.update(objects_sent, hash, [subscriber], fn obj_receivers ->
          obj_receivers ++ [subscriber]
        end)
      end
    end)
  end

  defp do_gc_objects_sent() do
    Process.send_after(self(), :gc_objects_sent, @gc_objects_sent_interval)
  end
end
