defmodule CoreChannelTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Client, Channel, GeneralizedAccount}
  alias AeppSDK.Utils.{Encoding, Transaction}

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
          public: "ak_2qRMVEKj7CWXLsBz1wtWANLyq4xBTdvFMSXpcKvmXb8RySumiX",
          secret:
            "4ea197c1717de46debbd0ea35a24e28e473e98f5aa328bdbe389e82262b6c5ff1a3ad4ef3f2c48fad6c5719ae9e2c6107013165733c455c7b992927247e61d1"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client2 =
      Client.new(
        %{
          public: "ak_fvRLMDGGFUSNbQcokMyM3RmagHBFX2vmcaSAnB7UTkwvKnb9G",
          secret:
            "49cb5ce722e59df4c4ccc99ff168653c9f08a09dc1ffebbc48956c3bb2474d52585ffcdfb2f44a42e1cca0879fcbc2c3562a0bf04d50686d80050579ff204935"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client3 =
      Client.new(
        %{
          public: "ak_mexPLgurwPYLKgLBM885hwiobHnv4c12s5Gi3UuSPZDhYLrmx",
          secret:
            "cc86e9d5127fac3225b00c8c1ac552b31b64c4ed9545e36240aa54a7988f72256564ad224800dec63ae4f48cf23486a43862af660d7877d953027ddaccd68327"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    source_code = "contract Authorization =

        function auth(auth_value : bool) =
          auth_value"
    auth = [auth_contract_source: source_code, auth_args: ["true"], fee: 100_000_000_000]

    [
      client: client,
      client1: client1,
      client2: client2,
      client3: client3,
      auth: auth,
      source_code: source_code
    ]
  end

  @tag :travis_test
  test "create, deposit, withdraw and close_mutual channel", setup_data do
    %{client: client, client1: client1} = setup_data

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client1.keypair.public,
               10_000_000_000_000
             )
           )

    assert {:ok, [create_tx, create_sig]} =
             Channel.create(
               client,
               1000,
               client1.keypair.public,
               1000,
               1000,
               1000,
               100,
               Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^create_tx, create_sig1]} = Transaction.sign_tx(create_tx, client1)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(client, create_tx, signatures_list: [create_sig, create_sig1])

    assert {:ok, %{channel_amount: channel_amount, id: ^channel_id}} =
             Channel.get_by_pubkey(client, channel_id)

    assert match?(2_000, channel_amount)

    assert {:ok, [deposit_tx, deposit_sig]} =
             Channel.deposit(
               setup_data.client,
               1_000_000_000_000,
               channel_id,
               2,
               Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^deposit_tx, deposit_sig1]} = Transaction.sign_tx(deposit_tx, client1)

    assert match?(
             {:ok, _},
             Channel.post(client, deposit_tx, signatures_list: [deposit_sig, deposit_sig1])
           )

    assert {:ok, %{channel_amount: channel_amount, id: ^channel_id}} =
             Channel.get_by_pubkey(client, channel_id)

    assert match?(1_000_000_002_000, channel_amount)

    assert {:ok, [withdraw_tx, withdraw_sig]} =
             Channel.withdraw(
               client,
               channel_id,
               client.keypair.public,
               2_000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               3
             )

    assert {:ok, [^withdraw_tx, withdraw_sig1]} = Transaction.sign_tx(withdraw_tx, client1)

    assert match?(
             {:ok, _},
             Channel.post(client, withdraw_tx, signatures_list: [withdraw_sig, withdraw_sig1])
           )

    assert {:ok, %{channel_amount: channel_amount, id: ^channel_id}} =
             Channel.get_by_pubkey(client, channel_id)

    assert match?(1_000_000_000_000, channel_amount)

    assert {:ok, [close_mutual_tx, close_mutual_sig]} =
             Channel.close_mutual(client, channel_id, 70_000, 0)

    assert {:ok, [^close_mutual_tx, close_mutual_sig1]} =
             Transaction.sign_tx(close_mutual_tx, client1)

    assert match?(
             {:ok, _},
             Channel.post(client, close_mutual_tx,
               signatures_list: [close_mutual_sig, close_mutual_sig1]
             )
           )

    assert match?(
             {:ok, %{reason: "Channel not found"}},
             Channel.get_by_pubkey(client, channel_id)
           )
  end

  @tag :travis_test
  test "Channel workflow with generalized accounts", setup_data do
    %{client: client, client2: client2, client3: client3, auth: auth, source_code: source_code} =
      setup_data

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client2.keypair.public,
               1_000_000_000_000_000_000
             )
           )

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client3.keypair.public,
               1_000_000_000_000_000_000
             )
           )

    GeneralizedAccount.attach(client2, source_code, "auth", [])
    GeneralizedAccount.attach(client3, source_code, "auth", [])

    assert {:ok, [tx, create_meta_tx, []]} =
             AeppSDK.Channel.create(
               client2,
               1000,
               client3.keypair.public,
               1000,
               1000,
               1000,
               100,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^tx, create_meta_tx1, []]} = AeppSDK.Utils.Transaction.sign_tx(tx, client3, auth)

    assert {:ok, %{channel_id: channel_id}} =
             AeppSDK.Channel.post(client2, create_meta_tx, inner_tx: create_meta_tx1, tx: tx)

    assert {:ok, %{id: ^channel_id}} = AeppSDK.Channel.get_by_pubkey(client2, channel_id)

    {:ok, %{round: round}} = AeppSDK.Channel.get_by_pubkey(client2, channel_id)
    next_round = round + 1

    assert {:ok, [deposit_tx, deposit_meta_tx, deposit_sig]} =
             AeppSDK.Channel.deposit(
               client2,
               100_000_000_000,
               channel_id,
               next_round,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^deposit_tx, deposit_meta_tx1, deposit_sig1]} =
             AeppSDK.Utils.Transaction.sign_tx(deposit_tx, client3, auth)

    assert {:ok, _} =
             AeppSDK.Channel.post(client2, deposit_meta_tx,
               inner_tx: deposit_meta_tx1,
               tx: deposit_tx
             )

    {:ok, %{round: round}} = AeppSDK.Channel.get_by_pubkey(client2, channel_id)
    next_round = round + 1

    assert {:ok, [withdraw_tx, withdraw_meta_tx, withdraw_sig]} =
             AeppSDK.Channel.withdraw(
               client2,
               channel_id,
               client2.keypair.public,
               2000,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round,
               auth: auth
             )

    assert {:ok, [^withdraw_tx, withdraw_meta_tx1, withdraw_sig1]} =
             AeppSDK.Utils.Transaction.sign_tx(withdraw_tx, client3, auth)

    assert {:ok, _} =
             AeppSDK.Channel.post(client2, withdraw_meta_tx,
               inner_tx: withdraw_meta_tx1,
               tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_meta_tx, close_mutual_sig]} =
             AeppSDK.Channel.close_mutual(client2, channel_id, 1000, 1000, auth: auth)

    assert {:ok, [^close_mutual_tx, close_mutual_meta_tx1, close_mutual_sig1]} =
             AeppSDK.Utils.Transaction.sign_tx(close_mutual_tx, client3, auth)

    assert {:ok, _} =
             AeppSDK.Channel.post(client2, close_mutual_meta_tx,
               inner_tx: close_mutual_meta_tx1,
               tx: close_mutual_tx
             )
  end

  @tag :travis_test
  test "Channel workflow with initiator basic and responder generalized accounts", setup_data do
    %{client: client, client2: client2, auth: auth, source_code: source_code} = setup_data

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client2.keypair.public,
               1_000_000_000_000_000_000
             )
           )

    GeneralizedAccount.attach(client2, source_code, "auth", [])

    assert {:ok, [tx, sig]} =
             AeppSDK.Channel.create(
               client,
               1000,
               client2.keypair.public,
               1000,
               1000,
               1000,
               100,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^tx, create_meta_tx, []]} = AeppSDK.Utils.Transaction.sign_tx(tx, client2, auth)

    assert {:ok, %{channel_id: channel_id}} =
             AeppSDK.Channel.post(client, create_meta_tx, signatures_list: [sig], inner_tx: tx)

    assert {:ok, %{id: ^channel_id, round: round}} =
             AeppSDK.Channel.get_by_pubkey(client, channel_id)

    next_round = round + 1

    assert {:ok, [deposit_tx, deposit_sig]} =
             AeppSDK.Channel.deposit(
               client,
               100_000_000_000,
               channel_id,
               next_round,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^deposit_tx, deposit_meta_tx, []]} =
             AeppSDK.Utils.Transaction.sign_tx(deposit_tx, client2, auth)

    assert {:ok, _} =
             AeppSDK.Channel.post(client, deposit_meta_tx,
               signatures_list: [deposit_sig],
               inner_tx: deposit_tx
             )

    {:ok, %{round: round}} = AeppSDK.Channel.get_by_pubkey(client, channel_id)
    next_round = round + 1

    assert {:ok, [withdraw_tx, withdraw_sig]} =
             AeppSDK.Channel.withdraw(
               client,
               channel_id,
               client2.keypair.public,
               2000,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round
             )

    assert {:ok, [^withdraw_tx, withdraw_meta_tx, []]} =
             AeppSDK.Utils.Transaction.sign_tx(withdraw_tx, client2, auth)

    assert {:ok, _} =
             AeppSDK.Channel.post(client, withdraw_meta_tx,
               signatures_list: [withdraw_sig],
               inner_tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_sig]} =
             AeppSDK.Channel.close_mutual(client, channel_id, 1000, 1000)

    assert {:ok, [^close_mutual_tx, close_mutual_meta_tx, []]} =
             AeppSDK.Utils.Transaction.sign_tx(close_mutual_tx, client2, auth)

    assert {:ok, _} =
             AeppSDK.Channel.post(client, close_mutual_meta_tx,
               signatures_list: [close_mutual_sig],
               inner_tx: close_mutual_tx
             )
  end

  @tag :travis_test
  test "Channel workflow with initiator generalized and responder basic accounts", setup_data do
    %{client: client, client2: client2, auth: auth, source_code: source_code} = setup_data

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client2.keypair.public,
               1_000_000_000_000_000_000
             )
           )

    GeneralizedAccount.attach(client2, source_code, "auth", [])

    assert {:ok, [tx, create_meta_tx, []]} =
             AeppSDK.Channel.create(
               client2,
               1000,
               client.keypair.public,
               1000,
               1000,
               1000,
               100,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^tx, create_sig]} = AeppSDK.Utils.Transaction.sign_tx(tx, client)

    assert {:ok, %{channel_id: channel_id}} =
             AeppSDK.Channel.post(client2, create_meta_tx,
               signatures_list: [create_sig],
               inner_tx: tx
             )

    assert {:ok, %{id: ^channel_id, round: round}} =
             AeppSDK.Channel.get_by_pubkey(client, channel_id)

    next_round = round + 1

    assert {:ok, [deposit_tx, deposit_meta_tx, []]} =
             AeppSDK.Channel.deposit(
               client2,
               100_000_000_000,
               channel_id,
               next_round,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^deposit_tx, deposit_sig]} = AeppSDK.Utils.Transaction.sign_tx(deposit_tx, client)

    assert {:ok, _} =
             AeppSDK.Channel.post(client2, deposit_meta_tx,
               signatures_list: [deposit_sig],
               inner_tx: deposit_tx
             )

    {:ok, %{round: round}} = AeppSDK.Channel.get_by_pubkey(client, channel_id)
    next_round = round + 1

    assert {:ok, [withdraw_tx, withdraw_meta_tx, []]} =
             AeppSDK.Channel.withdraw(
               client2,
               channel_id,
               client.keypair.public,
               2000,
               AeppSDK.Utils.Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round,
               auth: auth
             )

    assert {:ok, [^withdraw_tx, withdraw_sig]} = AeppSDK.Utils.Transaction.sign_tx(withdraw_tx, client)

    assert {:ok, _} =
             AeppSDK.Channel.post(client2, withdraw_meta_tx,
               signatures_list: [withdraw_sig],
               inner_tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_meta_tx, []]} =
             AeppSDK.Channel.close_mutual(client2, channel_id, 1000, 1000, auth: auth)

    assert {:ok, [^close_mutual_tx, close_mutual_sig]} =
             AeppSDK.Utils.Transaction.sign_tx(close_mutual_tx, client)

    assert {:ok, _} =
             AeppSDK.Channel.post(client2, close_mutual_meta_tx,
               signatures_list: [close_mutual_sig],
               inner_tx: close_mutual_tx
             )
  end
end
