defmodule CoreListenerTest do
  use ExUnit.Case

  alias Core.{Client, Listener, Account}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
          secret:
            "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    [client: client]
  end

  test "start listener, receive messages", setup_data do
    {:ok, %{peer_pubkey: peer_pubkey}} = Core.Chain.get_node_info(setup_data.client)

    Listener.start(
      ["aenode://#{peer_pubkey}@localhost:3015"],
      "my_test",
      "kh_2KhFJSdz1BwrvEWe9fFBRBpWoweoaZuTiYLWwUPh21ptuDE8UQ"
    )

    public_key = setup_data.client.keypair.public

    Listener.subscribe(:key_blocks, self())
    Listener.subscribe(:micro_blocks, self())
    Listener.subscribe(:transactions, self())
    Listener.subscribe(:pool_transactions, self())
    Listener.subscribe(:spend_transactions, self(), public_key)
    Listener.subscribe(:pool_spend_transactions, self(), public_key)

    Account.spend(setup_data.client, public_key, 100)

    # receive one of each of the events that we've subscribed to,
    # we don't know the order in which the messages have been sent
    receive_and_check_message(public_key, setup_data.client)
    receive_and_check_message(public_key, setup_data.client)
    receive_and_check_message(public_key, setup_data.client)
    receive_and_check_message(public_key, setup_data.client)
    receive_and_check_message(public_key, setup_data.client)
    receive_and_check_message(public_key, setup_data.client)
    receive_and_check_message(public_key, setup_data.client)

    :ok = Listener.stop()
  end

  defp receive_and_check_message(public_key, client) do
    receive do
      {type, _} = message ->
        case message do
          {:transactions, txs} ->
            assert :ok = check_txs(txs, public_key, client, false)

          {:pool_transactions, txs} ->
            assert :ok = check_txs(txs, public_key, client, false)

          {:spend_transactions, txs} ->
            assert :ok = check_txs([txs], public_key, client, true)

          {:pool_spend_transactions, txs} ->
            assert :ok = check_txs([txs], public_key, client, false)

          {:key_blocks, _} ->
            :ok

          {:micro_blocks, _} ->
            :ok

          {:tx_confirmations, %{status: :confirmed} = msg} ->
            :ok

          _ ->
            flunk("Received invalid message")
        end

        Listener.unsubscribe(type, self())
    after
      15000 -> flunk("Didn't receive message")
    end
  end

  defp check_txs(txs, public_key, client, check_confirmations) do
    case txs do
      [
        %{
          hash: hash,
          tx: %{
            sender_id: ^public_key,
            recipient_id: ^public_key,
            amount: 100,
            ttl: 0,
            payload: "",
            type: :spend_tx
          }
        }
      ] ->
        if check_confirmations do
          Listener.check_tx_confirmations(client, hash, 1, self())
        end

        :ok

      _ ->
        :error
    end
  end
end
