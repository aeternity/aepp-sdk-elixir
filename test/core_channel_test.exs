defmodule CoreChannelTest do
  use ExUnit.Case

  alias AeppSDK.Channel.OnChain, as: Channel
  alias AeppSDK.{Account, Client, GeneralizedAccount}
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

    client4 =
      Client.new(
        %{
          public: "ak_2B468wUNwgHtESYbaeQXZk36fUmndQKsG8aprstgqE6byL18M4",
          secret:
            "1ff1c56cf2679c044c52b8da67bd1b042fea415bf860e539b2cf407b252fb6349a85f286b60b8ee376be835925d6ac15b94c63b3d0ed9708fc62f9bbd1dde07b"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client5 =
      Client.new(
        %{
          public: "ak_GxXeeEKHfiK3f6qR8Rdt6ik1xYviC3z6SN3kMzKiUfQrjpz1B",
          secret:
            "40441c3007c712337f58919fe487def196f4de027bf14be542ce21f7707192c6243bb2e9296cfe273a0d0566dcc076f8f8eef0f60fd97682fe40e46db49e1e48"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client6 =
      Client.new(
        %{
          public: "ak_2QMwfcRqwxf1FFqdCYmkYrHbNBqJy1RKyTugEK2A5WtusbGa9w",
          secret:
            "19a5698cb636f81607b8ed55b3ae366712813f6f13e0f03b57211f7626ae2a62b8bd8302338dff66643c639c37ac60f810e43497526cd278a778b5d8a5175ce2"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client7 =
      Client.new(
        %{
          public: "ak_2EcM58EbynxZaiRvK9Ccis8y9bvAbvHRqoY83Zs4BrUs11a9Lm",
          secret:
            "461c34577692bb4353aaf9687f15afe5b60a68fa7e5cc872897548d0cf1b38eea299125ac1dd2ee55d20489d4ee67fa459fb0ded2ea0e343038dd5a32db42e31"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client8 =
      Client.new(
        %{
          public: "ak_7ZQ885tCvrFnPDfckds75SYVdNEaUX8XQaJ2k2gQZRy9Rwg7o",
          secret:
            "4d366d4024ff74c9f55965b6ab8b30f313e4b8e14e1507f225ef55b0511c6ff90ee460913d08e819815154bf37b2478b7563fad8489d03ce4ad547cda0fa1534"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client9 =
      Client.new(
        %{
          public: "ak_UNqFo8p82KNCHg8mvs3XATtNQoaS6LKq61tYY1MA7fERmgiTY",
          secret:
            "c50ba51d801734372462c14313536c908ea94cbdc342e48f34063e28f9f406593e2957cc5b8b024bf597b6f591109fe6ac97eb3e7708ca5861b544a3cfa8c501"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    source_code = "contract Authorization =

        entrypoint auth(auth_value : bool) =
          auth_value"
    auth = [auth_contract_source: source_code, auth_args: ["true"], fee: 100_000_000_000]

    [
      client: client,
      client1: client1,
      client2: client2,
      client3: client3,
      client4: client4,
      client5: client5,
      client6: client6,
      client7: client7,
      client8: client8,
      client9: client9,
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
             Channel.create(
               client2,
               1000,
               client3.keypair.public,
               1000,
               1000,
               1000,
               100,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^tx, create_meta_tx1, []]} = Transaction.sign_tx(tx, client3, auth)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(client2, create_meta_tx, inner_tx: create_meta_tx1, tx: tx)

    assert {:ok, %{id: ^channel_id}} = Channel.get_by_pubkey(client2, channel_id)

    {:ok, %{round: round}} = Channel.get_by_pubkey(client2, channel_id)
    next_round = round + 1

    assert {:ok, [deposit_tx, deposit_meta_tx, deposit_sig]} =
             Channel.deposit(
               client2,
               100_000_000_000,
               channel_id,
               next_round,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^deposit_tx, deposit_meta_tx1, deposit_sig1]} =
             Transaction.sign_tx(deposit_tx, client3, auth)

    assert {:ok, _} =
             Channel.post(client2, deposit_meta_tx,
               inner_tx: deposit_meta_tx1,
               tx: deposit_tx
             )

    {:ok, %{round: round}} = Channel.get_by_pubkey(client2, channel_id)
    next_round = round + 1

    assert {:ok, [withdraw_tx, withdraw_meta_tx, withdraw_sig]} =
             Channel.withdraw(
               client2,
               channel_id,
               client2.keypair.public,
               2000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round,
               auth: auth
             )

    assert {:ok, [^withdraw_tx, withdraw_meta_tx1, withdraw_sig1]} =
             Transaction.sign_tx(withdraw_tx, client3, auth)

    assert {:ok, _} =
             Channel.post(client2, withdraw_meta_tx,
               inner_tx: withdraw_meta_tx1,
               tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_meta_tx, close_mutual_sig]} =
             Channel.close_mutual(client2, channel_id, 1000, 1000, auth: auth)

    assert {:ok, [^close_mutual_tx, close_mutual_meta_tx1, close_mutual_sig1]} =
             Transaction.sign_tx(close_mutual_tx, client3, auth)

    assert {:ok, _} =
             Channel.post(client2, close_mutual_meta_tx,
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
             Channel.create(
               client,
               1000,
               client2.keypair.public,
               1000,
               1000,
               1000,
               100,
               Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^tx, create_meta_tx, []]} = Transaction.sign_tx(tx, client2, auth)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(client, create_meta_tx, signatures_list: [sig], inner_tx: tx)

    assert {:ok, %{id: ^channel_id, round: round}} = Channel.get_by_pubkey(client, channel_id)

    next_round = round + 1

    assert {:ok, [deposit_tx, deposit_sig]} =
             Channel.deposit(
               client,
               100_000_000_000,
               channel_id,
               next_round,
               Encoding.prefix_encode_base58c("st", <<0::256>>)
             )

    assert {:ok, [^deposit_tx, deposit_meta_tx, []]} =
             Transaction.sign_tx(deposit_tx, client2, auth)

    assert {:ok, _} =
             Channel.post(client, deposit_meta_tx,
               signatures_list: [deposit_sig],
               inner_tx: deposit_tx
             )

    {:ok, %{round: round}} = Channel.get_by_pubkey(client, channel_id)
    next_round = round + 1

    assert {:ok, [withdraw_tx, withdraw_sig]} =
             Channel.withdraw(
               client,
               channel_id,
               client2.keypair.public,
               2000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round
             )

    assert {:ok, [^withdraw_tx, withdraw_meta_tx, []]} =
             Transaction.sign_tx(withdraw_tx, client2, auth)

    assert {:ok, _} =
             Channel.post(client, withdraw_meta_tx,
               signatures_list: [withdraw_sig],
               inner_tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_sig]} =
             Channel.close_mutual(client, channel_id, 1000, 1000)

    assert {:ok, [^close_mutual_tx, close_mutual_meta_tx, []]} =
             Transaction.sign_tx(close_mutual_tx, client2, auth)

    assert {:ok, _} =
             Channel.post(client, close_mutual_meta_tx,
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
             Channel.create(
               client2,
               1000,
               client.keypair.public,
               1000,
               1000,
               1000,
               100,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^tx, create_sig]} = Transaction.sign_tx(tx, client)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(client2, create_meta_tx,
               signatures_list: [create_sig],
               inner_tx: tx
             )

    assert {:ok, %{id: ^channel_id, round: round}} = Channel.get_by_pubkey(client, channel_id)

    next_round = round + 1

    assert {:ok, [deposit_tx, deposit_meta_tx, []]} =
             Channel.deposit(
               client2,
               100_000_000_000,
               channel_id,
               next_round,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               auth: auth
             )

    assert {:ok, [^deposit_tx, deposit_sig]} = Transaction.sign_tx(deposit_tx, client)

    assert {:ok, _} =
             Channel.post(client2, deposit_meta_tx,
               signatures_list: [deposit_sig],
               inner_tx: deposit_tx
             )

    {:ok, %{round: round}} = Channel.get_by_pubkey(client, channel_id)
    next_round = round + 1

    assert {:ok, [withdraw_tx, withdraw_meta_tx, []]} =
             Channel.withdraw(
               client2,
               channel_id,
               client.keypair.public,
               2000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round,
               auth: auth
             )

    assert {:ok, [^withdraw_tx, withdraw_sig]} = Transaction.sign_tx(withdraw_tx, client)

    assert {:ok, _} =
             Channel.post(client2, withdraw_meta_tx,
               signatures_list: [withdraw_sig],
               inner_tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_meta_tx, []]} =
             Channel.close_mutual(client2, channel_id, 1000, 1000, auth: auth)

    assert {:ok, [^close_mutual_tx, close_mutual_sig]} =
             Transaction.sign_tx(close_mutual_tx, client)

    assert {:ok, _} =
             Channel.post(client2, close_mutual_meta_tx,
               signatures_list: [close_mutual_sig],
               inner_tx: close_mutual_tx
             )
  end

  @tag :travis_test
  test "create channel, close_solo, slash and settle", setup_data do
    %{client: client, client4: client4, client5: client5} = setup_data
    initiator_amt = 30_000_000_000
    responder_amt = 70_000_000_000

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client4.keypair.public,
               1_000_000_000_000_000
             )
           )

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client5.keypair.public,
               1_000_000_000_000_000
             )
           )

    # Create channel
    assert {:ok, [create_tx, create_sig]} =
             Channel.create(
               client4,
               initiator_amt,
               client5.keypair.public,
               responder_amt,
               1,
               20,
               10,
               Encoding.prefix_encode_base58c(
                 "st",
                 <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                   185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>
               )
             )

    assert {:ok, [^create_tx, create_sig1]} = Transaction.sign_tx(create_tx, client5)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(client4, create_tx, signatures_list: [create_sig, create_sig1])

    # Close solo tx
    assert {:ok, _} =
             Channel.close_solo(
               client4,
               channel_id,
               <<>>,
               accounts:
                 {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184, 167,
                    123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54, 240>>,
                  %{
                    cache:
                      {3,
                       {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184,
                          167, 123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54,
                          240>>,
                        [
                          <<>>,
                          <<>>,
                          <<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                            118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                            112, 176>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                           118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                           112, 176>>,
                         [
                           <<58, 133, 242, 134, 182, 11, 142, 227, 118, 190, 131, 89, 37, 214,
                             172, 21, 185, 76, 99, 179, 208, 237, 151, 8, 252, 98, 249, 187, 209,
                             221, 224, 123>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil,
                         {<<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          [
                            <<52, 59, 178, 233, 41, 108, 254, 39, 58, 13, 5, 102, 220, 192, 118,
                              248, 248, 238, 240, 246, 15, 217, 118, 130, 254, 64, 228, 109, 180,
                              158, 30, 72>>,
                            <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                          ], nil, nil}}, nil}}
                  }}
             )

    # Slash tx
    assert {:ok, _} =
             Channel.slash(
               client4,
               channel_id,
               <<248, 211, 11, 1, 248, 132, 184, 64, 103, 143, 97, 54, 143, 62, 96, 188, 175, 138,
                 69, 94, 189, 154, 187, 232, 24, 124, 227, 118, 222, 228, 194, 201, 138, 30, 163,
                 139, 234, 56, 102, 49, 147, 29, 134, 97, 135, 69, 62, 62, 89, 133, 45, 99, 164,
                 238, 174, 83, 132, 129, 253, 64, 92, 8, 33, 203, 46, 197, 115, 87, 191, 250, 221,
                 0, 184, 64, 218, 115, 120, 42, 135, 32, 185, 172, 64, 147, 81, 28, 252, 62, 61,
                 174, 23, 187, 214, 191, 235, 45, 229, 160, 92, 36, 8, 248, 130, 109, 163, 27, 57,
                 181, 80, 131, 182, 231, 33, 13, 76, 193, 217, 176, 176, 134, 228, 122, 52, 81,
                 237, 128, 105, 191, 57, 99, 140, 104, 242, 118, 170, 157, 214, 6, 184, 73, 248,
                 71, 57, 1, 161, 6, 79, 170, 117, 156, 23, 1, 16, 54, 197, 235, 149, 116, 88, 255,
                 224, 120, 70, 14, 30, 170, 25, 182, 198, 157, 53, 41, 226, 230, 204, 75, 170,
                 223, 3, 192, 160, 104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46,
                 166, 249, 5, 206, 185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144,
                 107>>,
               accounts:
                 {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184, 167,
                    123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54, 240>>,
                  %{
                    cache:
                      {3,
                       {<<192, 111, 88, 20, 45, 33, 69, 2, 151, 130, 233, 71, 11, 221, 101, 184,
                          167, 123, 74, 128, 115, 113, 34, 233, 205, 57, 169, 234, 11, 204, 54,
                          240>>,
                        [
                          <<>>,
                          <<>>,
                          <<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                            118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                            112, 176>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<7, 136, 134, 164, 145, 33, 39, 79, 153, 107, 203, 149, 176, 234, 74,
                           118, 68, 253, 71, 192, 23, 88, 107, 255, 169, 105, 39, 183, 41, 43,
                           112, 176>>,
                         [
                           <<58, 133, 242, 134, 182, 11, 142, 227, 118, 190, 131, 89, 37, 214,
                             172, 21, 185, 76, 99, 179, 208, 237, 151, 8, 252, 98, 249, 187, 209,
                             221, 224, 123>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil,
                         {<<181, 54, 180, 239, 130, 16, 187, 166, 170, 125, 75, 101, 25, 218, 209,
                            128, 212, 56, 75, 225, 21, 47, 4, 89, 95, 58, 5, 165, 128, 110, 47,
                            30>>,
                          [
                            <<52, 59, 178, 233, 41, 108, 254, 39, 58, 13, 5, 102, 220, 192, 118,
                              248, 248, 238, 240, 246, 15, 217, 118, 130, 254, 64, 228, 109, 180,
                              158, 30, 72>>,
                            <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                          ], nil, nil}}, nil}}
                  }}
             )

    # Settle tx
    assert {:ok, _} = Channel.settle(client4, channel_id, initiator_amt, responder_amt)

    assert match?(
             {:ok, %{reason: "Channel not found"}},
             Channel.get_by_pubkey(client4, channel_id)
           )
  end

  @tag :travis_test
  test "create channel, snapshot", setup_data do
    %{client: client, client6: client6, client7: client7} = setup_data

    initiator_amt = 30_000_000_000
    responder_amt = 70_000_000_000

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client6.keypair.public,
               1_000_000_000_000_000
             )
           )

    assert match?(
             {:ok, _},
             Account.spend(
               client,
               client7.keypair.public,
               1_000_000_000_000_000
             )
           )

    # Create channel
    assert {:ok, [create_tx, create_sig]} =
             Channel.create(
               client6,
               initiator_amt,
               client7.keypair.public,
               responder_amt,
               1,
               20,
               10,
               Encoding.prefix_encode_base58c(
                 "st",
                 <<104, 40, 209, 191, 182, 107, 186, 113, 55, 214, 98, 133, 46, 166, 249, 5, 206,
                   185, 30, 65, 61, 161, 194, 140, 93, 163, 214, 28, 44, 126, 144, 107>>
               )
             )

    assert {:ok, [^create_tx, create_sig1]} = Transaction.sign_tx(create_tx, client7)

    assert {:ok, %{channel_id: channel_id}} =
             Channel.post(client6, create_tx, signatures_list: [create_sig, create_sig1])

    {:ok, %{state_hash: state_hash_create}} = Channel.get_by_pubkey(client6, channel_id)

    assert {:ok, _} =
             Channel.snapshot_solo(
               client6,
               channel_id,
               <<248, 211, 11, 1, 248, 132, 184, 64, 189, 85, 177, 158, 63, 228, 58, 49, 130, 243,
                 140, 226, 243, 148, 27, 45, 181, 131, 160, 118, 17, 83, 57, 252, 79, 125, 17, 66,
                 24, 141, 36, 201, 246, 103, 197, 220, 243, 55, 208, 220, 242, 184, 218, 232, 239,
                 180, 68, 197, 198, 67, 148, 46, 244, 215, 183, 104, 6, 116, 105, 147, 163, 30,
                 71, 8, 184, 64, 56, 168, 162, 166, 91, 36, 180, 37, 49, 220, 215, 99, 239, 45,
                 121, 175, 128, 207, 45, 52, 168, 149, 50, 107, 38, 226, 64, 63, 54, 236, 238,
                 150, 104, 159, 232, 14, 24, 134, 12, 33, 108, 232, 158, 222, 210, 242, 63, 78,
                 134, 146, 242, 211, 11, 122, 230, 252, 254, 103, 150, 139, 88, 80, 47, 6, 184,
                 73, 248, 71, 57, 1, 161, 6, 76, 31, 36, 226, 145, 19, 154, 231, 247, 12, 200,
                 250, 255, 20, 63, 23, 196, 86, 255, 190, 186, 6, 111, 186, 119, 166, 86, 126, 7,
                 231, 197, 244, 43, 192, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43>>
             )

    {:ok, %{state_hash: state_hash_snapshot}} = Channel.get_by_pubkey(client6, channel_id)
    assert state_hash_create != state_hash_snapshot
  end
end
