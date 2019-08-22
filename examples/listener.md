# Example `AeppSDK.Listener` usage

The listener service notifies processes for the events that they've subscribed to. This is done by sending messages to them, meaning that they must be able to handle incoming messages. Here's an example implementation of a `GenServer` that handles a number of different events:

``` elixir
defmodule EventHandler do
  use GenServer

  alias AeppSDK.Listener

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    Listener.start("ae_uat")
    Listener.subscribe(:key_blocks, self())
    Listener.subscribe(:micro_blocks, self())

    Listener.subscribe(
      :spend_transactions,
      self(),
      "ak_Y2Hueaa44EMAgfDy9zWePFpVToikqDFq5M4pkKe2zuYsk6wau"
    )

    {:ok, %{key_blocks: [], micro_blocks: [], spend_transactions: []}}
  end

  def handle_info({:key_blocks, key_block}, %{key_blocks: key_blocks} = state) do
    Logger.info(fn -> "Received new key block: #{inspect(key_block)}" end)
    {:noreply, %{state | key_blocks: [key_block | key_blocks]}}
  end

  def handle_info(
        {:spend_transactions, spend_transaction},
        %{spend_transactions: spend_transactions} = state
      ) do
    Logger.info(fn -> "Received new spend transaction: #{inspect(spend_transaction)}" end)
    {:noreply, %{state | spend_transactions: [spend_transaction | spend_transactions]}}
  end

  def handle_info({:micro_blocks, micro_block}, %{micro_blocks: micro_blocks} = state) do
    Logger.info(fn -> "Received new micro block: #{inspect(micro_block)}" end)
    {:noreply, %{state | micro_blocks: [micro_block | micro_blocks]}}
  end
end
```
