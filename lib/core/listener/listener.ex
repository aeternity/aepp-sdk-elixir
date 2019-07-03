defmodule Core.Listener do
  use GenServer

  alias Core.Listener.Supervisor

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start(network_id) do
    Supervisor.start_link(network_id)
  end

  def init(_) do
    {:ok,
     %{
       micro_block_subscribers: [],
       key_block_subscribers: [],
       txs_subscribers: [],
       spend_transaction_subscribers: [],
       oracle_query_subscribers: [],
       oracle_response_subscribers: []
     }}
  end

  def subscribe_for_micro_blocks(subscriber_pid) do
    GenServer.call(__MODULE__, {:subscribe_for_micro_blocks, subscriber_pid})
  end

  def unsubscribe_from_micro_blocks(subscriber_pid) do
    GenServer.call(__MODULE__, {:unsubscribe_from_micro_blocks, subscriber_pid})
  end

  def subscribe_for_key_blocks(subscriber_pid) do
    GenServer.call(__MODULE__, {:subscribe_for_key_blocks, subscriber_pid})
  end

  def unsubscribe_from_key_blocks(subscriber_pid) do
    GenServer.call(__MODULE__, {:unsubscribe_from_key_blocks, subscriber_pid})
  end

  def subscribe_for_txs(subscriber_pid) do
    GenServer.call(__MODULE__, {:subscribe_for_txs, subscriber_pid})
  end

  def unsubscribe_from_txs(subscriber_pid) do
    GenServer.call(__MODULE__, {:unsubscribe_from_txs, subscriber_pid})
  end

  def subscribe_for_spend_transactions(subscriber_pid, pubkey) do
    GenServer.call(__MODULE__, {:subscribe_for_spend_transactions, subscriber_pid, pubkey})
  end

  def unsubscribe_from_spend_transactions(subscriber_pid, pubkey) do
    GenServer.call(__MODULE__, {:unsubscribe_from_spend_transactions, subscriber_pid, pubkey})
  end

  def subscribe_for_oracle_queries(subscriber_pid, oracle_id) do
    GenServer.call(__MODULE__, {:subscribe_for_oracle_queries, subscriber_pid, oracle_id})
  end

  def unsubscribe_from_oracle_queries(subscriber_pid, oracle_id) do
    GenServer.call(__MODULE__, {:unsubscribe_from_oracle_queries, subscriber_pid, oracle_id})
  end

  def subscribe_for_oracle_response(subscriber_pid, query_id) do
    GenServer.call(__MODULE__, {:subscribe_for_oracle_response, subscriber_pid, query_id})
  end

  def unsubscribe_from_oracle_response(subscriber_pid, query_id) do
    GenServer.call(__MODULE__, {:unsubscribe_from_oracle_response, subscriber_pid, query_id})
  end

  def notify_for_micro_block(micro_block) do
    GenServer.cast(__MODULE__, {:notify_for_micro_block, micro_block})
  end

  def notify_for_key_block(key_block) do
    GenServer.cast(__MODULE__, {:notify_for_key_block, key_block})
  end

  def notify_for_txs(txs) do
    GenServer.cast(__MODULE__, {:notify_for_txs, txs})
  end

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
        {:notify_for_micro_block, micro_block},
        %{
          micro_block_subscribers: micro_block_subscribers
        } = state
      ) do
    send_object_to_subscribers(micro_block, micro_block_subscribers)

    {:noreply, state}
  end

  def handle_cast(
        {:notify_for_key_block, key_block},
        %{
          key_block_subscribers: key_block_subscribers
        } = state
      ) do
    send_object_to_subscribers(key_block, key_block_subscribers)

    {:noreply, state}
  end

  def handle_cast(
        {:notify_for_txs, txs},
        %{
          txs_subscribers: txs_subscribers
        } = state
      ) do
    send_object_to_subscribers(txs, txs_subscribers)

    {:noreply, state}
  end

  defp add_subscriber(subscriber, subscribers) do
    if Enum.member?(subscribers, subscriber) do
      subscribers
    else
      [subscriber | subscribers]
    end
  end

  defp send_object_to_subscribers(object, subscribers) do
    Enum.each(subscribers, fn subscriber ->
      send(subscriber, object)
    end)
  end
end
