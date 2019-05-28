defmodule CoreChainTest do
  use ExUnit.Case

  alias Core.{Chain, Client, Contract}

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
        datatype event = AddedNumberEvent(indexed int, string)

        record state = { number : int }

        function init(x : int) =
          { number = x }

        function add_to_number(x : int) =
          Chain.event(AddedNumberEvent(x, \"Added a number\"))
          state.number + x"

    [client: client, source_code: source_code]
  end

  @tag :travis_test
  test "height operations", setup_data do
    height_result = Chain.height(setup_data.client)
    assert match?({:ok, _}, height_result)

    {:ok, height} = height_result
    assert :ok == Chain.await_height(setup_data.client, height)
    assert :ok == Chain.await_height(setup_data.client, height + 1)
  end

  @tag :travis_test
  test "transaction operations", setup_data do
    {:ok,
     %{
       block_hash: block_hash,
       block_height: block_height,
       contract_id: contract_id,
       log: log,
       return_type: return_type,
       return_value: return_value,
       tx_hash: tx_hash
     }} =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"],
        fee: 10_000_000_000_000_000
      )

    assert :ok == Chain.await_transaction(setup_data.client, tx_hash)

    transaction_result =
      Chain.get_transaction(
        setup_data.client,
        tx_hash
      )

    assert match?(
             {:ok,
              %{
                block_hash: ^block_hash,
                block_height: ^block_height,
                hash: ^tx_hash
              }},
             transaction_result
           )

    transaction_info_result = Chain.get_transaction_info(setup_data.client, tx_hash)

    assert match?(
             {:ok,
              %{
                call_info: %{
                  contract_id: ^contract_id,
                  height: ^block_height,
                  log: ^log,
                  return_type: ^return_type,
                  return_value: ^return_value
                }
              }},
             transaction_info_result
           )

    pending_transactions_result = Chain.get_pending_transactions(setup_data.client)
    assert match?({:ok, _}, pending_transactions_result)
  end

  @tag :travis_test
  test "block operations", setup_data do
    {:ok,
     %{
       block_hash: block_hash,
       block_height: block_height,
       tx_hash: tx_hash
     }} =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"],
        fee: 10_000_000_000_000_000
      )

    current_generation_result = Chain.get_current_generation(setup_data.client)

    assert match?(
             {:ok, %{key_block: %{}}},
             current_generation_result
           )

    {:ok, %{key_block: %{hash: key_block_hash, height: height}, micro_blocks: micro_blocks}} =
      current_generation_result

    generation_result = Chain.get_generation(setup_data.client, key_block_hash)

    assert match?(
             {:ok, %{key_block: %{hash: ^key_block_hash, height: ^height}}},
             generation_result
           )

    generation_result = Chain.get_generation(setup_data.client, height)

    assert match?(
             {:ok, %{key_block: %{hash: ^key_block_hash, height: ^height}}},
             generation_result
           )

    micro_block_hash = List.last(micro_blocks)

    micro_block_transactions_result =
      Chain.get_micro_block_transactions(setup_data.client, micro_block_hash)

    assert match?(
             {:ok, [%{block_hash: ^block_hash, block_height: ^block_height, hash: ^tx_hash}]},
             micro_block_transactions_result
           )

    key_block_result = Chain.get_key_block(setup_data.client, key_block_hash)
    assert match?({:ok, %{hash: ^key_block_hash, height: ^height}}, key_block_result)
    key_block_result = Chain.get_key_block(setup_data.client, height)
    assert match?({:ok, %{hash: ^key_block_hash, height: ^height}}, key_block_result)

    micro_block_header_result = Chain.get_micro_block_header(setup_data.client, micro_block_hash)
    assert match?({:ok, %{hash: ^micro_block_hash}}, micro_block_header_result)
  end

  @tag :travis_test
  test "node info", setup_data do
    node_info_result = Chain.get_node_info(setup_data.client)

    assert match?(
             {:ok, %{peer_pubkey: _, status: _, node_beneficiary: _, node_pubkey: _, peers: _}},
             node_info_result
           )
  end
end
