defmodule CoreListenerTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Chain, Client, Contract, Listener}

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

    source_code = "contract Identity =
      datatype event =
        SomeEvent(bool, bits, bytes(8))
        | AnotherEvent(address, oracle(int, int), oracle_query(int, int))

      type state = unit

      stateful entrypoint emit_event() =
        Chain.event(SomeEvent(true, Bits.all, #123456789abcdef))
        Chain.event(AnotherEvent(ak_2bKhoFWgQ9os4x8CaeDTHZRGzUcSwcXYUrM12gZHKTdyreGRgG,
          ok_2YNyxd6TRJPNrTcEDCe9ra59SVUdp9FR9qWC5msKZWYD9bP9z5,
          oq_2oRvyowJuJnEkxy58Ckkw77XfWJrmRgmGaLzhdqb67SKEL1gPY))"
    [client: client, source_code: source_code]
  end

  test "start listener, receive messages", setup_data do
    {:ok, %{peer_pubkey: peer_pubkey}} = Chain.get_node_info(setup_data.client)

    Listener.start(
      ["aenode://#{peer_pubkey}@localhost:3015"],
      "my_test",
      "kh_2KhFJSdz1BwrvEWe9fFBRBpWoweoaZuTiYLWwUPh21ptuDE8UQ"
    )

    public_key = setup_data.client.keypair.public

    {:ok, %{contract_id: ct_address}} =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        []
      )

    Listener.subscribe_for_contract_events(setup_data.client, self(), ct_address)

    Listener.subscribe_for_contract_events(setup_data.client, self(), ct_address, "SomeEvent", [
      :bool,
      :bits,
      :bytes
    ])

    Listener.subscribe_for_contract_events(
      setup_data.client,
      self(),
      ct_address,
      "AnotherEvent",
      [:address, :oracle, :oracle_query]
    )

    {:ok, %{return_type: "ok"}} =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "emit_event",
        []
      )

    Listener.subscribe(:key_blocks, self())
    Listener.subscribe(:micro_blocks, self())
    Listener.subscribe(:transactions, self())
    Listener.subscribe(:pool_transactions, self())
    Listener.subscribe(:spend_transactions, self(), public_key)
    Listener.subscribe(:pool_spend_transactions, self(), public_key)

    Account.spend(setup_data.client, public_key, 100)

    # receive one of each of the events that we've subscribed to,
    # we don't know the order in which the messages have been sent
    Enum.each(0..9, fn _ ->
      receive_and_check_message(public_key, setup_data.client, ct_address)
    end)

    :ok = Listener.stop()
  end

  defp receive_and_check_message(public_key, client, contract_address) do
    receive do
      message ->
        case message do
          {:transactions, txs} ->
            assert :ok = check_txs(txs, public_key, client, false)

          {:pool_transactions, txs} ->
            assert :ok = check_txs(txs, public_key, client, false)

          {:spend_transactions, ^public_key, txs} ->
            assert :ok = check_txs(txs, public_key, client, true)

          {:pool_spend_transactions, ^public_key, txs} ->
            assert :ok = check_txs(txs, public_key, client, false)

          {:key_blocks, _} ->
            :ok

          {:micro_blocks, _} ->
            :ok

          {:tx_confirmations, %{status: :confirmed}} ->
            :ok

          {:contract_events,
           [
             %{
               address: ^contract_address,
               data: ""
             },
             %{
               address: ^contract_address,
               data: ""
             }
           ]} ->
            :ok

          {:contract_events, "SomeEvent",
           [
             %{
               address: ^contract_address,
               data: "",
               topics: [
                 "SomeEvent",
                 true,
                 115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_913_129_639_935,
                 81_985_529_216_486_895
               ]
             }
           ]} ->
            :ok

          {:contract_events, "AnotherEvent",
           [
             %{
               address: ^contract_address,
               data: "",
               topics: [
                 "AnotherEvent",
                 "ak_2bKhoFWgQ9os4x8CaeDTHZRGzUcSwcXYUrM12gZHKTdyreGRgG",
                 "ok_2YNyxd6TRJPNrTcEDCe9ra59SVUdp9FR9qWC5msKZWYD9bP9z5",
                 "oq_2oRvyowJuJnEkxy58Ckkw77XfWJrmRgmGaLzhdqb67SKEL1gPY"
               ]
             }
           ]} ->
            :ok

          _ ->
            flunk("Received invalid message")
        end

        Listener.unsubscribe(elem(message, 0), self())
    after
      30_000 -> flunk("Didn't receive message")
    end
  end

  defp check_txs(txs, public_key, client, check_confirmations) do
    case txs do
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
      } ->
        if check_confirmations do
          Listener.check_tx_confirmations(client, hash, 1, self())
        end

        :ok

      _ ->
        :error
    end
  end
end
