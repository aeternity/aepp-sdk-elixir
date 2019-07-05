defmodule CoreChannelTest do
  use ExUnit.Case

  alias Core.{Account, Client, Channel}
  alias Utils.{Encoding, Transaction}

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

    client1 =
      Client.new(
        %{
          public: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
          secret:
            "799ef7aa9ed8e3d58cd2492b7a569ccf967f3b63dc49ac2d0c9ea916d29cf8387ca99a8cd824b2a3efc3c6c5d500585713430575d4ce6999b202cb20f86019d8"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    [client: client, client1: client1]
  end

  @tag :travis_test
  test "create, deposit, withdraw and close_mutual channel", setup_data do
    assert match?(
             {:ok, _},
             Account.spend(setup_data.client, setup_data.client1.keypair.public, 1_000_000)
           )

    assert {:ok, [tx, sig]} =
             Channel.create(
               setup_data.client,
               1000,
               setup_data.client1.keypair.public,
               1000,
               1000,
               1000,
               100,
               Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^tx, sig1]} = Transaction.sign_tx(tx, setup_data.client1)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(setup_data.client, tx, signatures_list: [sig, sig1])

    assert {:ok, %{channel_amount: channel_amount, id: ^channel_id}} =
             Channel.get_by_pubkey(setup_data.client, channel_id)

    assert match?(2_000, channel_amount)

    assert {:ok, [tx, sig]} =
             Channel.deposit(
               setup_data.client,
               1_000_000_000_000,
               channel_id,
               2,
               Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^tx, sig1]} = Transaction.sign_tx(tx, setup_data.client1)
    assert match?({:ok, _}, Channel.post(setup_data.client, tx, signatures_list: [sig, sig1]))

    assert {:ok, %{channel_amount: channel_amount, id: ^channel_id}} =
             Channel.get_by_pubkey(setup_data.client, channel_id)

    assert match?(1_000_000_002_000, channel_amount)

    assert {:ok, [tx, sig]} =
             Channel.withdraw(
               setup_data.client,
               channel_id,
               setup_data.client.keypair.public,
               2_000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               3
             )

    assert {:ok, [^tx, sig1]} = Transaction.sign_tx(tx, setup_data.client1)
    assert match?({:ok, _}, Channel.post(setup_data.client, tx, signatures_list: [sig, sig1]))

    assert {:ok, %{channel_amount: channel_amount, id: ^channel_id}} =
             Channel.get_by_pubkey(setup_data.client, channel_id)

    assert match?(1_000_000_000_000, channel_amount)

    assert {:ok, [tx, sig]} = Channel.close_mutual(setup_data.client, channel_id, 70_000, 0)
    assert {:ok, [tx, sig1]} = Transaction.sign_tx(tx, setup_data.client1)
    assert match?({:ok, _}, Channel.post(setup_data.client, tx, signatures_list: [sig, sig1]))

    assert match?(
             {:ok, %{reason: "Channel not found"}},
             Channel.get_by_pubkey(setup_data.client, channel_id)
           )
  end
end
