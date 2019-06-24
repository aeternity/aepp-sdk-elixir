defmodule Core.Listener.Worker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(parent_pid) do
    {:ok,
     %{
       parent: parent_pid,
       micro_block_listeners: [],
       key_block_listeners: [],
       spend_transaction_listeners: [],
       oracle_query_listeners: [],
       oracle_response_listeners: []
     }}
  end

  def add_micro_block_listener(listener_pid) do
    GenServer.cast(__MODULE__, {:add_micro_block_listener, listener_pid})
  end

  def add_key_block_listener(listener_pid) do
    GenServer.cast(__MODULE__, {:add_key_block_listener, listener_pid})
  end

  def add_spend_transaction_listener(listener_pid, pubkey) do
    GenServer.cast(__MODULE__, {:add_spend_transaction_listener, listener_pid, pubkey})
  end

  def add_oracle_query_listener(listener_pid, oracle_id) do
    GenServer.cast(__MODULE__, {:add_oracle_query_listener, listener_pid, oracle_id})
  end

  def add_oracle_response_listener(listener_pid, query_id) do
    GenServer.cast(__MODULE__, {:add_oracle_response_listener, listener_pid, query_id})
  end

  def signal_for_micro_block(micro_block) do
    GenServer.cast(__MODULE__, {:signal_for_micro_block, micro_block})
  end

  def signal_for_key_block(key_block) do
    GenServer.cast(__MODULE__, {:signal_for_key_block, key_block})
  end

  def handle_cast(
        {:add_micro_block_listener, listener_pid},
        _from,
        %{micro_block_listeners: micro_block_listeners} = state
      ) do
    {:ok, %{state | micro_block_listeners: [listener_pid | micro_block_listeners]}}
  end

  def handle_cast(
        {:add_key_block_listener, listener_pid},
        _from,
        %{key_block_listeners: key_block_listeners} = state
      ) do
    {:ok, %{state | key_block_listeners: [listener_pid | key_block_listeners]}}
  end

  def handle_cast(
        {:add_spend_transaction_listener, listener_pid, pubkey},
        _from,
        %{
          spend_transaction_listeners: spend_transaction_listeners
        } = state
      ) do
    {:ok,
     %{
       state
       | spend_transaction_listeners: [
           %{listener: listener_pid, pubkey: pubkey} | spend_transaction_listeners
         ]
     }}
  end

  def handle_cast(
        {:add_oracle_query_listener, listener_pid, oracle_id},
        _from,
        %{oracle_query_listeners: oracle_query_listeners} = state
      ) do
    {:ok,
     %{
       state
       | oracle_query_listeners: [
           %{listener: listener_pid, oracle_id: oracle_id} | oracle_query_listeners
         ]
     }}
  end

  def handle_cast(
        {:add_oracle_response_listener, listener_pid, query_id},
        _from,
        %{
          oracle_response_listeners: oracle_response_listeners
        } = state
      ) do
    {:ok,
     %{
       state
       | oracle_response_listeners: [
           %{listener: listener_pid, query_id: query_id} | oracle_response_listeners
         ]
     }}
  end

  def handle_cast(
        {:signal_for_micro_block, micro_block},
        _from,
        %{
          micro_block_listeners: micro_block_listeners
        } = state
      ) do
    send_object_to_listeners(micro_block, micro_block_listeners)

    {:ok, state}
  end

  def handle_cast(
        {:signal_for_key_block, key_block},
        _from,
        %{
          key_block_listeners: key_block_listeners
        } = state
      ) do
    send_object_to_listeners(key_block, key_block_listeners)

    {:ok, state}
  end

  defp send_object_to_listeners(object, listeners) do
    Enum.each(listeners, fn listener ->
      send(listener, object)
    end)
  end
end
