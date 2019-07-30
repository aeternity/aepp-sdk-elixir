defmodule Core.Listener do
  @moduledoc """
  A listener service that connects to peers in a network and notifies processes for new blocks and transactions.
  """
  use GenServer

  alias Core.Listener.Supervisor, as: ListenerSup
  alias Core.Client
  alias Utils.Encoding
  alias AeternityNode.Api.Transaction, as: TransactionApi
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Model.{GenericSignedTx, Error}

  @gc_objects_sent_interval 10_000
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

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Start the listener for mainnet or testnet (`network_id` - `"ae_mainnet"` or `"ae_uat"`).
  Starting the listener is required before subscribing to any events.

  ## Example
      iex> Core.Listener.start("ae_uat")
      {:ok, #PID<0.261.0>}
  """
  @spec start(String.t(), non_neg_integer()) :: {:ok, pid()}
  def start(network_id, port \\ @default_port)

  def start(network_id, port) when network_id in ["ae_mainnet", "ae_uat"],
    do:
      ListenerSup.start_link(%{network: network_id, initial_peers: [], genesis: nil, port: port})

  def start(_, _),
    do:
      {:error,
       "Cannot start Listener for a non-predefined network, use start/3 for private networks"}

  @doc """
  Start the listener for a custom/private network with a set of user defined peers, network ID and genesis hash.
  Starting the listener is required before subscribing to any events.
  A peer is defined in the following format:
  `"aenode://peer_pubkey@host:port"` i.e. `"aenode://pp_2L8A5vSjnkLtfFNpJNgP9HbmGLD7ZAGFxoof47N8L4yyLAyyMi@18.136.37.63:3015"`

  ## Example
      iex> Core.Listener.start(
            ["aenode://pp_2L8A5vSjnkLtfFNpJNgP9HbmGLD7ZAGFxoof47N8L4yyLAyyMi@18.136.37.63:3015"],
            "localnet",
            "kh_2Eo9AVWHxTKio278ccANnwtr9hkUpzb1nLePfUzs7StwWyJ2xB"
          )
      {:ok, #PID<0.214.0>}
  """
  @spec start(list(String.t()), String.t(), Encoding.base58c(), non_neg_integer()) :: {:ok, pid()}
  def start(peers, network_id, genesis_hash, port \\ @default_port)
      when is_list(peers) and is_binary(network_id) and is_binary(genesis_hash),
      do:
        ListenerSup.start_link(%{
          initial_peers: peers,
          network: network_id,
          genesis: genesis_hash,
          port: port
        })

  @doc """
  Stop the listener

  ## Example
      iex> Core.Listener.stop()
      :ok
  """
  @spec stop() :: :ok
  def stop(), do: Supervisor.stop(ListenerSup)

  @doc false
  def init(_) do
    {:ok,
     %{
       objects_sent: [],
       gc_scheduled: false,
       subscribers: %{
         tx_confirmations: [],
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

  @doc """
  Subscribe a process to notifications for a general event.
  These events are the following (passed as an atom):
    - `:micro_blocks`
    - `:key_blocks`
    - `:transactions`
    - `:pool_transactions`

  Micro blocks are in a light format, meaning that they don't contain any transactions.
  Subscribing to `:transactions` will notify for any mined transactions, while `:pool_transactions`
  will notify for any new transactions added to the pool.

  ## Example
      iex> Core.Listener.subscribe(:key_blocks, self())
      iex> flush()
      {:key_blocks,
        %{
         beneficiary: "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv",
         height: 107613,
         info: "cb_AAAAAfy4hFE=",
         miner: "ak_V9dqj32R728EmdtaeXmGC7Zn94oAtje2mU2R9vQeCE3uDF52z",
         nonce: 15682880022608178725,
         pow_evidence: [36880953, 49948618, 71657014, 77943721, 103433465, 109309407,
          127422545, 140895507, 181678786, 182358531, 186372470, 188704699, 189292674,
          201708293, 215741852, 233410604, 255594855, 257736633, 266211649, 269325362,
          274670268, 292854435, 295392989, 307433512, 312822688, 330979144, 339358365,
          340662380, 356338119, 356413992, 363610991, 364811647, 387037152, 387943984,
          438683034, 469469067, 472181309, 479842054, 484418139, 506523084, 517149088,
          532705934],
         prev_hash: "mh_nxXxmga7AU5T3N7GGUV4s5T8YvJYEZnXGTaaUoLgBStva1dT4",
         prev_key_hash: "kh_j47UCW6UYYN4FhcMwQgynpAKdddKeAkPUUFyF6G35hArsfo8Q",
         root_hash: "bs_2hpHUMa7VWVTdcwwSm4L7U1CLMXqTbhrjZYJ2FMLz1LZCKfoCG",
         target: 504011610,
         time: 1562765121744,
         version: 3
       }}
      :ok
  """
  @spec subscribe(atom(), pid()) :: :ok
  def subscribe(event, subscriber_pid) when event in @general_events do
    case assert_listener_started() do
      :ok ->
        GenServer.call(__MODULE__, {:subscribe, event, subscriber_pid})

      {:error, _} = err ->
        err
    end
  end

  def subscribe(event, _) when event in @filtered_events,
    do: {:error, "Missing filter for event: #{event}"}

  def subscribe(event, _),
    do: {:error, "Unknown event to subscribe to: #{event}"}

  @doc """
  Subscribe a process to notifications for a filterable event i.e. a spend transaction
  with a specific recipient or an oracle query transaction that targets a specific oracle.

  These events are the following and are filtered by a specific property:
    - `:spend_transactions` - recipient
    - `:oracle_queries` - oracle ID
    - `:oracle_responses` - oracle query ID
    - `:pool_spend_transactions` - recipient
    - `:pool_oracle_queries` - oracle ID
    - `:pool_oracle_responses` - oracle query ID

  ## Example
      iex> Core.Listener.subscribe(:spend_transactions, self(), "ak_2siRXKa5hT1YpR2oPwcU3LDpYzAdAcgt6HSNUt61NNV9NqkRP9")
      iex> flush()
      {:spend_transactions,
        %{
          hash: "th_2Z9198iTQbBBE3jdeFxJQNMHqGNSESxG7PyTs3vU3JZUjYs319",
          tx: %{
            amount: 100,
            fee: 16640000000,
            nonce: 3,
            payload: "",
            recipient_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            sender_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            ttl: 0,
            type: :spend_tx
          }
        }
      }
      :ok
  """
  @spec subscribe(atom(), pid(), Encoding.base58c()) :: :ok
  def subscribe(event, subscriber_pid, filter) when event in @filtered_events do
    case assert_listener_started() do
      :ok ->
        GenServer.call(__MODULE__, {:subscribe, event, subscriber_pid, filter})

      {:error, _} = err ->
        err
    end
  end

  def subscribe(event, _, _), do: {:error, "Unknown event to subscribe to: #{event}"}

  @doc """
  Subscribe a process to be notified whether or not a transaction with a given hash
  has been confirmed after a `block_count` amount of key blocks. Requires a client to be
  passed as the first argument as it makes requests to a node.

  ## Example
      iex> Core.Client.new(
        %{
          public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
          secret:
            "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
        },
        "ae_uat",
        "https://sdk-testnet.aepps.com/v2",
        "https://sdk-testnet.aepps.com/v2"
      )
      iex> tx_hash = "th_2RMnW2GYbS2n5mwRtjFjb61ZgSNzNNUHGWU5EBmQXeUZfpP4vM"
      iex> block_count = 10
      iex> Core.Listener.check_tx_confirmations(client, tx_hash, block_count, self())
      iex> flush()
      {:tx_confirmations,
       %{
         height: 111283,
         status: :confirmed,
         tx_hash: "th_2RMnW2GYbS2n5mwRtjFjb61ZgSNzNNUHGWU5EBmQXeUZfpP4vM"
       }}
      :ok
  """
  @spec check_tx_confirmations(Client.t(), Encoding.base58c(), non_neg_integer(), pid()) ::
          :ok | {:error, any()}
  def check_tx_confirmations(
        %Client{connection: connection},
        tx_hash,
        block_count,
        subscriber_pid
      ) do
    with :ok <- assert_listener_started(),
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection) do
      GenServer.call(
        __MODULE__,
        {:check_tx_confirmations, connection, tx_hash, height + block_count, subscriber_pid}
      )
    else
      {:error, _} = err -> err
    end
  end

  @spec unsubscribe(atom(), pid()) :: :ok
  def unsubscribe(event, subscriber_pid) when event in @general_events do
    case assert_listener_started() do
      :ok ->
        GenServer.call(__MODULE__, {:unsubscribe, event, subscriber_pid})

      {:error, _} = err ->
        err
    end
  end

  def unsubscribe(event, _) when event in @filtered_events,
    do: {:error, "Missing filter for event: #{event}"}

  def unsubscribe(event, _),
    do: {:error, "Unknown event to unsubscribe from: #{event}"}

  @doc """
  Unsubscribe a process from a filterable event.

  ## Example
      iex> Core.Listener.unsubscribe(:spend_transactions, self(), "ak_2siRXKa5hT1YpR2oPwcU3LDpYzAdAcgt6HSNUt61NNV9NqkRP9")
      :ok
  """
  def unsubscribe(event, subscriber_pid, filter) when event in @filtered_events do
    case assert_listener_started() do
      :ok ->
        GenServer.call(__MODULE__, {:unsubscribe, event, subscriber_pid, filter})

      {:error, _} = err ->
        err
    end
  end

  def unsubscribe(event, _, _), do: {:error, "Unknown event to unsubscribe from: #{event}"}

  @doc false
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
        {:check_tx_confirmations, connection, tx_hash, height, subscriber_pid},
        _from,
        %{subscribers: %{tx_confirmations: tx_confirmations} = subscribers} = state
      ) do
    updated_tx_confirmations =
      add_subscriber(
        tx_confirmations,
        %{subscriber: subscriber_pid, connection: connection, tx_hash: tx_hash, height: height}
      )

    {:reply, :ok,
     %{state | subscribers: %{subscribers | tx_confirmations: updated_tx_confirmations}}}
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
          gc_scheduled: gc_scheduled,
          subscribers: %{tx_confirmations: tx_confirmations} = subscribers
        } = state
      ) do
    {updated_tx_confirmations, updated_objects_sent} =
      if Enum.member?(objects_sent, hash) do
        {tx_confirmations, objects_sent}
      else
        send_object_to_subscribers(
          event,
          data,
          hash,
          subscribers,
          objects_sent
        )
      end

    updated_gc_scheduled =
      if gc_scheduled do
        gc_scheduled
      else
        do_gc_objects_sent()

        true
      end

    {:noreply,
     %{
       state
       | objects_sent: updated_objects_sent,
         gc_scheduled: updated_gc_scheduled,
         subscribers: %{subscribers | tx_confirmations: updated_tx_confirmations}
     }}
  end

  def handle_info(:gc_objects_sent, %{objects_sent: objects_sent} = state) do
    half_count = floor(Enum.count(objects_sent) / 2)

    gc_objects_sent =
      if half_count > 0 do
        Enum.drop(objects_sent, half_count)
      else
        objects_sent
      end

    {:noreply, %{state | objects_sent: gc_objects_sent, gc_scheduled: false}}
  end

  defp add_subscriber(subscribers, subscriber) do
    if Enum.member?(subscribers, subscriber) do
      subscribers
    else
      [subscriber | subscribers]
    end
  end

  defp send_object_to_subscribers(
         event,
         object,
         hash,
         %{tx_confirmations: tx_confirmations} = subscribers,
         objects_sent
       ) do
    %{^event => general_event_subscribers} = subscribers

    objects_sent1 =
      send_general_event_object(event, object, hash, general_event_subscribers, objects_sent)

    updated_tx_confirmations =
      if event == :key_blocks do
        send_confirmation_info(tx_confirmations, object.height)
      else
        tx_confirmations
      end

    updated_objects_sent =
      case event do
        event when event in [:transactions, :pool_transactions] ->
          send_specific_event_objects(hash, object, objects_sent1, event, subscribers)

        _ ->
          objects_sent1
      end

    {updated_tx_confirmations, updated_objects_sent}
  end

  defp determine_filter(event, %{tx: tx}) do
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

  defp send_specific_event_objects(hash, object, objects_sent, event, subscribers) do
    Enum.reduce(object, objects_sent, fn tx, acc ->
      filter = determine_filter(event, tx)

      case filter do
        {filtered_event, value} ->
          %{^filtered_event => specific_event_subscribers} = subscribers

          send_filtered_event_object(
            filtered_event,
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
  end

  defp send_general_event_object(event, object, hash, subscribers, objects_sent) do
    Enum.reduce(subscribers, objects_sent, fn subscriber, acc ->
      send_and_update_objects_sent(event, object, hash, subscriber, acc)
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
          send_and_update_objects_sent(event, object, hash, subscriber_pid, objects_sent)
        else
          acc
        end
      end
    )
  end

  defp send_and_update_objects_sent(event, object, hash, subscriber, objects_sent) do
    send(subscriber, {event, object})

    objects_sent ++ [hash]
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

  defp transaction_in_state?(connection, tx_hash) do
    case TransactionApi.get_transaction_by_hash(connection, tx_hash) do
      {:ok, %GenericSignedTx{}} ->
        true

      {:ok, %Error{}} ->
        false
    end
  end

  defp send_confirmation_info(tx_confirmation_subscribers, current_height) do
    Enum.reduce(tx_confirmation_subscribers, tx_confirmation_subscribers, fn %{
                                                                               connection:
                                                                                 connection,
                                                                               tx_hash: tx_hash,
                                                                               height: height,
                                                                               subscriber: pid
                                                                             } = confirmation_info,
                                                                             acc ->
      cond do
        height == current_height && transaction_in_state?(connection, tx_hash) ->
          send(pid, {:tx_confirmations, %{tx_hash: tx_hash, status: :confirmed, height: height}})
          List.delete(acc, confirmation_info)

        height == current_height && !transaction_in_state?(connection, tx_hash) ->
          send(
            pid,
            {:tx_confirmations, %{tx_hash: tx_hash, status: :not_in_state, height: height}}
          )

          List.delete(acc, confirmation_info)

        true ->
          acc
      end
    end)
  end

  defp assert_listener_started() do
    case Process.whereis(ListenerSup) do
      nil ->
        {:error, "Listener not started, use start/1 or start/3"}

      _pid ->
        :ok
    end
  end
end