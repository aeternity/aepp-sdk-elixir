defmodule Core.Listener do
  @moduledoc """
  A listener service that connects to peers in a network and notifies processes for new blocks and transactions.
  """
  use GenServer

  alias Core.Listener.Supervisor

  @gc_objects_sent_interval 180_000
  @general_events [:micro_blocks, :key_blocks, :transactions, :pool_transactions]
  @transactions_filtered_events [:spend_transactions, :oracle_queries, :oracle_responses]
  @pool_transactions_filtered_events [
    :pool_spend_transactions,
    :pool_oracle_queries,
    :pool_oracle_responses
  ]
  @filtered_events @transactions_filtered_events ++ @pool_transactions_filtered_events
  @notifiable_events @general_events ++ @filtered_events

  @default_port 3016

  @doc """
  false
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Start the listener for mainnet or testnet
  """
  @spec start(String.t(), non_neg_integer()) :: {:ok, pid()}
  def start(network_id, port \\ @default_port)

  def start(network_id, port) when network_id in ["ae_mainnet", "ae_uat"],
    do: Supervisor.start_link(%{network: network_id, initial_peers: [], genesis: nil, port: port})

  def start(_, _),
    do:
      {:error,
       "Cannot start Listener for a non-predefined network, use start/3 for private networks"}

  @doc """
  Start the listener for a custom/private network with a set of user defined peers, network ID and genesis hash.
  A peer is defined in the following format:
  "aenode://peer_pubkey@host:port" i.e. "aenode://pp_2L8A5vSjnkLtfFNpJNgP9HbmGLD7ZAGFxoof47N8L4yyLAyyMi@18.136.37.63:3015"
  """
  @spec start(list(String.t()), String.t(), Encoding.base58c(), non_neg_integer()) :: {:ok, pid()}
  def start(peers, network_id, genesis_hash, port \\ @default_port)
      when is_list(peers) and is_binary(network_id) and is_binary(genesis_hash),
      do:
        Supervisor.start_link(%{
          initial_peers: peers,
          network: network_id,
          genesis: genesis_hash,
          port: port
        })

  @doc """
  false
  """
  def init(_) do
    do_gc_objects_sent()

    {:ok,
     %{
       objects_sent: %{},
       subscribers: %{
         micro_blocks: [],
         key_blocks: [],
         transactions: [],
         pool_transactions: [],
         spend_transactions: [],
         oracle_queries: [],
         oracle_responses: [],
         pool_spend_transactions: [],
         pool_oracle_queries: [],
         pool_oracle_responses: []
       }
     }}
  end

  def subscribe(event, subscriber_pid) when event in @general_events do
    GenServer.call(__MODULE__, {:subscribe, event, subscriber_pid})
  end

  def subscribe(event, _) when event in @filtered_events,
    do: {:error, "Missing filter for event: #{event}"}

  def subscribe(event, _),
    do: {:error, "Unknown event to subscribe for: #{event}"}

  def subscribe(event, subscriber_pid, filter) when event in @filtered_events do
    GenServer.call(__MODULE__, {:subscribe, event, subscriber_pid, filter})
  end

  def subscribe(event, _, _), do: {:error, "Unknown event to subscribe for: #{event}"}

  def unsubscribe(event, subscriber_pid) when event in @general_events do
    GenServer.call(__MODULE__, {:unsubscribe, event, subscriber_pid})
  end

  def unsubscribe(event, _) when event in @filtered_events,
    do: {:error, "Missing filter for event: #{event}"}

  def unsubscribe(event, _),
    do: {:error, "Unknown event to unsubscribe from: #{event}"}

  def unsubscribe(event, subscriber_pid, filter) when event in @filtered_events do
    GenServer.call(__MODULE__, {:unsubscribe, event, subscriber_pid, filter})
  end

  def unsubscribe(event, _, _), do: {:error, "Unknown event to unsubscribe from: #{event}"}

  def notify(event, data, hash) when event in @notifiable_events do
    GenServer.cast(__MODULE__, {:notify, event, data, hash})
  end

  def notify(event, _, _), do: {:error, "Unknown event to notify for: #{event}"}

  def handle_call(
        {:subscribe, event, subscriber_pid},
        _from,
        %{subscribers: subscribers} = state
      ) do
    %{^event => event_subscribers} = subscribers
    updated_event_subscribers = add_subscriber(event_subscribers, subscriber_pid)

    {:reply, :ok, %{state | subscribers: %{subscribers | event => updated_event_subscribers}}}
  end

  def handle_call(
        {:subscribe, event, subscriber_pid, filter},
        _from,
        %{subscribers: subscribers} = state
      ) do
    %{^event => event_subscribers} = subscribers

    updated_event_subscribers =
      add_subscriber(
        event_subscribers,
        %{subscriber: subscriber_pid, filter: filter}
      )

    {:reply, :ok,
     %{
       state
       | subscribers: %{subscribers | event => updated_event_subscribers}
     }}
  end

  def handle_call(
        {:unsubscribe, event, subscriber_pid},
        _from,
        %{
          subscribers: subscribers
        } = state
      ) do
    %{^event => event_subscribers} = subscribers
    updated_event_subscribers = List.delete(event_subscribers, subscriber_pid)

    {:reply, :ok, %{state | subscribers: %{subscribers | event => updated_event_subscribers}}}
  end

  def handle_call(
        {:unsubscribe, event, subscriber_pid, filter},
        _from,
        %{subscribers: subscribers} = state
      ) do
    %{^event => event_subscribers} = subscribers

    updated_event_subscribers =
      List.delete(event_subscribers, %{
        subscriber: subscriber_pid,
        filter: filter
      })

    {:reply, :ok,
     %{
       state
       | subscribers: %{subscribers | event => updated_event_subscribers}
     }}
  end

  def handle_cast(
        {:notify, event, data, hash},
        %{
          objects_sent: objects_sent,
          subscribers: subscribers
        } = state
      ) do
    updated_objects_sent =
      send_object_to_subscribers(
        event,
        data,
        hash,
        subscribers,
        objects_sent
      )

    {:noreply, %{state | objects_sent: updated_objects_sent}}
  end

  def handle_info(:gc_objects_sent, state) do
    do_gc_objects_sent()

    {:noreply, %{state | objects_sent: %{}}}
  end

  defp add_subscriber(subscribers, subscriber) do
    if Enum.member?(subscribers, subscriber) do
      subscribers
    else
      [subscriber | subscribers]
    end
  end

  defp send_object_to_subscribers(event, object, hash, subscribers, objects_sent) do
    %{^event => general_event_subscribers} = subscribers

    objects_sent1 =
      send_general_event_object(event, object, hash, general_event_subscribers, objects_sent)

    if Enum.member?(event, [:transactions, :pool_transactions]) do
      Enum.reduce(object, objects_sent1, fn tx, acc ->
        filter = determine_filter(event, tx)

        case filter do
          {filtered_event, value} ->
            %{^filtered_event => specific_event_subscribers} = subscribers

            send_filtered_event_object(
              event,
              tx,
              hash,
              specific_event_subscribers,
              acc,
              value
            )

          _ ->
            acc
        end
      end)
    else
      objects_sent1
    end
  end

  defp determine_filter(event, tx) do
    [spend_tx_event, oracle_query_event, oracle_response_event] = get_specific_events(event)

    case tx do
      # spend
      %{sender_id: _, recipient_id: recipient} ->
        {spend_tx_event, recipient}

      # oracle query
      %{sender_id: _, oracle_id: oracle_id} ->
        {oracle_query_event, oracle_id}

      # oracle response
      %{oracle_id: _, query_id: query_id} ->
        {oracle_response_event, query_id}

      _ ->
        nil
    end
  end

  defp send_general_event_object(event, object, hash, subscribers, objects_sent) do
    Enum.reduce(subscribers, objects_sent, fn subscriber, acc ->
      object_receivers = Map.get(objects_sent, hash, [])

      if Enum.member?(object_receivers, subscriber) do
        acc
      else
        send_and_update_objects_sent(event, object, hash, subscriber, objects_sent)
      end
    end)
  end

  defp send_filtered_event_object(event, object, hash, subscribers, objects_sent, object_value) do
    Enum.reduce(
      subscribers,
      objects_sent,
      fn %{
           subscriber: subscriber_pid,
           filter: filter
         },
         acc ->
        if object_value == filter do
          if Enum.member?(acc, subscriber_pid) do
            acc
          else
            send_and_update_objects_sent(event, object, hash, subscriber_pid, objects_sent)
          end
        else
          acc
        end
      end
    )
  end

  defp send_and_update_objects_sent(event, object, hash, subscriber, objects_sent) do
    send(subscriber, {event, object})

    Map.update(objects_sent, hash, [subscriber], fn obj_receivers ->
      obj_receivers ++ [subscriber]
    end)
  end

  defp get_specific_events(:transactions) do
    @transactions_filtered_events
  end

  defp get_specific_events(:pool_transactions) do
    @pool_transactions_filtered_events
  end

  defp do_gc_objects_sent() do
    Process.send_after(self(), :gc_objects_sent, @gc_objects_sent_interval)
  end
end
