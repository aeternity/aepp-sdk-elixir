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
      ["aenode://#{peer_pubkey}:3015"],
      "my_test",
      "kh_2KhFJSdz1BwrvEWe9fFBRBpWoweoaZuTiYLWwUPh21ptuDE8UQ"
    )

    Listener.subscribe(:key_blocks, self())

    receive do
      {:key_blocks, _} -> :ok
    end

    Listener.subscribe(:micro_blocks, self())
    Account.spend(setup_data.client, setup_data.client.keypair.public, 100)

    receive do
      {:micro_blocks, _} -> :ok
    end

    Listener.subscribe(:transactions, self())

    Account.spend(setup_data.client, setup_data.client.keypair.public, 100)

    receive do
      {:transactions, _} -> :ok
    end

    Listener.subscribe(:pool_transactions, self())

    Account.spend(setup_data.client, setup_data.client.keypair.public, 100)

    receive do
      {:pool_transactions, _} -> :ok
    end
  end
end
