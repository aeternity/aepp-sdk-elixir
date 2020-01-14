defmodule CoreListenerTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Chain, Contract, Listener}

  setup_all do
    Code.require_file("test_utils.ex", "test/")
    TestUtils.get_test_data()
  end

  @tag :travis_test
  test "start listener, receive messages", setup_data do
    {:ok, %{peer_pubkey: peer_pubkey}} = Chain.get_node_info(setup_data.client)

    Listener.start(
      ["aenode://#{peer_pubkey}@localhost:3015"],
      "my_test",
      "kh_2KhFJSdz1BwrvEWe9fFBRBpWoweoaZuTiYLWwUPh21ptuDE8UQ"
    )

    public_key = setup_data.client.keypair.public

    {:ok, %{contract_id: aevm_ct_address}} =
      Contract.deploy(
        setup_data.client,
        setup_data.aevm_source_code,
        [],
        vm: :aevm
      )

    {:ok, %{contract_id: fate_ct_address}} =
      Contract.deploy(
        setup_data.client,
        setup_data.fate_source_code,
        []
      )

    Listener.subscribe_for_contract_events(setup_data.client, self(), aevm_ct_address)

    Listener.subscribe_for_contract_events(setup_data.client, self(), fate_ct_address)

    Listener.subscribe_for_contract_events(
      setup_data.client,
      self(),
      aevm_ct_address,
      "SomeEvent",
      [
        :bool,
        :bits,
        :bytes
      ]
    )

    Listener.subscribe_for_contract_events(
      setup_data.client,
      self(),
      fate_ct_address,
      "SomeEvent",
      [
        :string
      ]
    )

    Listener.subscribe_for_contract_events(
      setup_data.client,
      self(),
      aevm_ct_address,
      "AnotherEvent",
      [:address, :oracle, :oracle_query]
    )

    Listener.subscribe_for_contract_events(
      setup_data.client,
      self(),
      fate_ct_address,
      "AnotherEvent",
      [:string]
    )

    {:ok, %{return_type: "ok"}} =
      Contract.call(
        setup_data.client,
        aevm_ct_address,
        setup_data.aevm_source_code,
        "emit_event",
        []
      )

    {:ok, %{return_type: "ok"}} =
      Contract.call(
        setup_data.client,
        fate_ct_address,
        setup_data.aevm_source_code,
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
      receive_and_check_message(public_key, setup_data.client, aevm_ct_address, fate_ct_address)
    end)

    :ok = Listener.stop()
  end

  defp receive_and_check_message(public_key, client, aevm_contract_address, fate_contract_address) do
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
               address: ^aevm_contract_address,
               data: ""
             },
             %{
               address: ^aevm_contract_address,
               data: ""
             }
           ]} ->
            :ok

          {:contract_events,
           [
             %{
               address: ^fate_contract_address,
               data: "another event"
             },
             %{
               address: ^fate_contract_address,
               data: "some event"
             }
           ]} ->
            :ok

          {:contract_events, "SomeEvent",
           [
             %{
               address: ^aevm_contract_address,
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

          {:contract_events, "SomeEvent",
           [
             %{
               address: ^fate_contract_address,
               data: "some event",
               topics: [
                 "SomeEvent"
               ]
             }
           ]} ->
            :ok

          {:contract_events, "AnotherEvent",
           [
             %{
               address: ^aevm_contract_address,
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

          {:contract_events, "AnotherEvent",
           [
             %{
               address: ^fate_contract_address,
               data: "another event",
               topics: [
                 "AnotherEvent"
               ]
             }
           ]} ->
            :ok

          _res ->
            flunk("Received invalid message")
        end

        Listener.unsubscribe(elem(message, 0), self())
    after
      45_000 -> flunk("Didn't receive message")
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
