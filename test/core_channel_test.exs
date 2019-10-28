defmodule CoreChannelTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Channel, Client, GeneralizedAccount}
  alias AeppSDK.Channel.OnChain, as: Channel
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
            "04ea197c1717de46debbd0ea35a24e28e473e98f5aa328bdbe389e82262b6c5ff1a3ad4ef3f2c48fad6c5719ae9e2c6107013165733c455c7b992927247e61d1"
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
          public: "ak_hZP2M8FamBSM6kNoMVwFK3JEsy4fZ9e7pRAw7HXKrSUg3B8nQ",
          secret:
            "739ee8e8a7ee8a5de64eb84bd04f37c7fc740144e28d0fc9d14790a477f794f85c17af1ad992980b675197d6936ebbd25c4eab2d481cf7a1a7123deab4d98506"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client5 =
      Client.new(
        %{
          public: "ak_287XG6Fied7M1W54mAtTnEzWbAPn6zHSf5Y84wXtp4nQBS7vmv",
          secret:
            "0175739f9d44ba397f3a5958b73a54e709424cbce81bc8a4912cac8155d2c33893d8844970c618fca06b0cdf8a16a54d4396c35123df2447602a305b4588f78e"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client6 =
      Client.new(
        %{
          public: "ak_2WeQqo3noHwnYmMnk4ChqNxAp2JM29WGxEeTtsGn2UVBoDs9cM",
          secret:
            "46f4ed7466546842e4edc29691204359f781b44e11e3453089b6da72dd0ce3fac7023c815e036a380c52f742a94d0efc175b0c6827395bc884515fd3b17006e3"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client7 =
      Client.new(
        %{
          public: "ak_jjy941vp3Q4wwY3v1jgTVR2TyyVLWXDrvUvfrJdgpv1SruZ1g",
          secret:
            "3b3d1368fc2ec950d006eaeb49639583e94f9fc6f11ed6e2c95257de8970b560610c5bb1fc419ae38f9115eac7b831d438b8c89a5ab0671d6c1c914020ad70bd"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client8 =
      Client.new(
        %{
          public: "ak_2iFnCL7GDmLynyh8yC7MLWYy3CmtGbxYPSLeo6fe5imc6awtUX",
          secret:
            "8b5b9735e8dd78c905873715dc6dcd87baf7d447ba22ae243447b6005ec5a1c8e15ec54c569b0c842f356d8c2efea48c194ec46539b1483136bd9dbb8ba8bb64"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    client9 =
      Client.new(
        %{
          public: "ak_rqa6wmPA1ZsUpeM662KDRBAWf3fBGdXFbBK5pL7JpRphEBasA",
          secret:
            "1f84dc340df6ac8f9bc42a8d5155ede2668dfdc07a395287b36c1eef7fa310b771297717acee7cbacc355faf76cae599180aa8a16c1ea0cb01bc718f0ee7b280"
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
               1_000,
               client1.keypair.public,
               1_000,
               1_000,
               1_000,
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
               1_000,
               client3.keypair.public,
               1_000,
               1_000,
               1_000,
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

    {:ok, %{round: round_}} = Channel.get_by_pubkey(client2, channel_id)
    next_round_ = round_ + 1

    assert {:ok, [withdraw_tx, withdraw_meta_tx, withdraw_sig]} =
             Channel.withdraw(
               client2,
               channel_id,
               2_000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round_,
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
             Channel.close_mutual(client2, channel_id, 1_000, 1_000, auth: auth)

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
               1_000,
               client2.keypair.public,
               1_000,
               1_000,
               1_000,
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

    {:ok, %{round: round_}} = Channel.get_by_pubkey(client, channel_id)
    next_round_ = round_ + 1

    assert {:ok, [withdraw_tx, withdraw_sig]} =
             Channel.withdraw(
               client,
               channel_id,
               2_000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round_
             )

    assert {:ok, [^withdraw_tx, withdraw_meta_tx, []]} =
             Transaction.sign_tx(withdraw_tx, client2, auth)

    assert {:ok, _} =
             Channel.post(client, withdraw_meta_tx,
               signatures_list: [withdraw_sig],
               inner_tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_sig]} =
             Channel.close_mutual(client, channel_id, 1_000, 1_000)

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
               1_000,
               client.keypair.public,
               1_000,
               1_000,
               1_000,
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

    {:ok, %{round: round_}} = Channel.get_by_pubkey(client, channel_id)
    next_round_ = round_ + 1

    assert {:ok, [withdraw_tx, withdraw_meta_tx, []]} =
             Channel.withdraw(
               client2,
               channel_id,
               2_000,
               Encoding.prefix_encode_base58c("st", <<0::256>>),
               next_round_,
               auth: auth
             )

    assert {:ok, [^withdraw_tx, withdraw_sig]} = Transaction.sign_tx(withdraw_tx, client)

    assert {:ok, _} =
             Channel.post(client2, withdraw_meta_tx,
               signatures_list: [withdraw_sig],
               inner_tx: withdraw_tx
             )

    assert {:ok, [close_mutual_tx, close_mutual_meta_tx, []]} =
             Channel.close_mutual(client2, channel_id, 1_000, 1_000, auth: auth)

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
               <<248, 210, 11, 1, 248, 132, 184, 64, 201, 113, 103, 241, 42, 81, 62, 1, 103, 105,
                 22, 251, 213, 10, 40, 106, 197, 217, 39, 51, 5, 44, 73, 142, 50, 78, 40, 208, 88,
                 116, 43, 53, 81, 6, 23, 241, 250, 225, 60, 76, 4, 174, 160, 24, 130, 33, 72, 1,
                 185, 121, 0, 233, 109, 122, 143, 66, 188, 5, 160, 35, 142, 26, 220, 2, 184, 64,
                 90, 28, 241, 181, 193, 50, 161, 54, 69, 243, 124, 105, 122, 228, 172, 8, 199,
                 166, 32, 131, 229, 16, 81, 237, 37, 44, 86, 1, 202, 62, 176, 168, 89, 137, 245,
                 105, 120, 166, 242, 61, 238, 182, 172, 144, 224, 208, 122, 177, 35, 133, 90, 76,
                 250, 235, 23, 132, 124, 23, 226, 16, 137, 50, 85, 5, 184, 72, 248, 70, 57, 2,
                 161, 6, 67, 28, 253, 157, 52, 56, 167, 245, 195, 204, 105, 111, 179, 9, 174, 138,
                 170, 157, 22, 18, 121, 142, 124, 182, 178, 196, 189, 31, 111, 81, 64, 49, 2, 160,
                 154, 233, 243, 226, 108, 37, 138, 14, 209, 86, 39, 89, 167, 191, 182, 94, 106,
                 233, 189, 108, 94, 31, 187, 28, 192, 85, 168, 253, 98, 98, 99, 158>>,
               accounts:
                 {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73, 245,
                    75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212, 51>>,
                  %{
                    cache:
                      {3,
                       {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73,
                          245, 75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212,
                          51>>,
                        [
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                            105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                            16>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                            52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                           105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                           16>>,
                         [
                           <<60, 23, 175, 26, 217, 146, 152, 11, 103, 81, 151, 214, 147, 110, 187,
                             210, 92, 78, 171, 45, 72, 28, 247, 161, 167, 18, 61, 234, 180, 217,
                             133, 6>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil, nil},
                        {<<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                           52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                         [
                           <<51, 216, 132, 73, 112, 198, 24, 252, 160, 107, 12, 223, 138, 22, 165,
                             77, 67, 150, 195, 81, 35, 223, 36, 71, 96, 42, 48, 91, 69, 136, 247,
                             142>>,
                           <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                         ], nil, nil}}}
                  }}
             )

    # Slash tx
    assert {:ok, _} =
             Channel.slash(
               client4,
               channel_id,
               <<248, 210, 11, 1, 248, 132, 184, 64, 145, 148, 30, 197, 5, 240, 183, 26, 184, 110,
                 253, 83, 1, 240, 198, 71, 193, 214, 193, 22, 202, 70, 234, 30, 157, 24, 219, 67,
                 15, 0, 223, 68, 118, 143, 137, 154, 195, 231, 18, 82, 28, 33, 169, 105, 139, 44,
                 139, 184, 115, 249, 149, 202, 50, 234, 107, 252, 10, 163, 184, 236, 43, 84, 34,
                 11, 184, 64, 232, 63, 222, 177, 255, 229, 215, 175, 11, 119, 122, 12, 47, 88,
                 143, 199, 191, 170, 176, 3, 163, 44, 192, 125, 35, 127, 69, 169, 247, 201, 234,
                 1, 204, 85, 143, 19, 156, 213, 69, 155, 252, 218, 91, 162, 99, 192, 26, 71, 122,
                 199, 100, 141, 109, 8, 158, 38, 100, 121, 194, 189, 237, 160, 78, 0, 184, 72,
                 248, 70, 57, 2, 161, 6, 67, 28, 253, 157, 52, 56, 167, 245, 195, 204, 105, 111,
                 179, 9, 174, 138, 170, 157, 22, 18, 121, 142, 124, 182, 178, 196, 189, 31, 111,
                 81, 64, 49, 3, 160, 154, 233, 243, 226, 108, 37, 138, 14, 209, 86, 39, 89, 167,
                 191, 182, 94, 106, 233, 189, 108, 94, 31, 187, 28, 192, 85, 168, 253, 98, 98, 99,
                 158>>,
               accounts:
                 {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73, 245,
                    75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212, 51>>,
                  %{
                    cache:
                      {3,
                       {<<140, 209, 91, 235, 172, 88, 191, 47, 80, 136, 11, 102, 92, 245, 219, 73,
                          245, 75, 162, 83, 27, 159, 121, 157, 30, 240, 117, 178, 254, 221, 212,
                          51>>,
                        [
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                            105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                            16>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                            52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>,
                          <<>>
                        ],
                        {<<2, 58, 110, 90, 245, 96, 254, 181, 44, 135, 34, 160, 19, 18, 26, 58,
                           105, 180, 85, 248, 214, 24, 47, 76, 178, 2, 26, 251, 26, 106, 195,
                           16>>,
                         [
                           <<60, 23, 175, 26, 217, 146, 152, 11, 103, 81, 151, 214, 147, 110, 187,
                             210, 92, 78, 171, 45, 72, 28, 247, 161, 167, 18, 61, 234, 180, 217,
                             133, 6>>,
                           <<201, 10, 1, 0, 133, 6, 252, 35, 172, 0>>
                         ], nil, nil},
                        {<<146, 113, 225, 29, 31, 110, 130, 50, 56, 165, 196, 118, 45, 126, 24,
                           52, 14, 30, 9, 56, 8, 221, 231, 24, 231, 73, 90, 1, 159, 0, 83, 192>>,
                         [
                           <<51, 216, 132, 73, 112, 198, 24, 252, 160, 107, 12, 223, 138, 22, 165,
                             77, 67, 150, 195, 81, 35, 223, 36, 71, 96, 42, 48, 91, 69, 136, 247,
                             142>>,
                           <<201, 10, 1, 0, 133, 16, 76, 83, 60, 0>>
                         ], nil, nil}}}
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
               <<248, 210, 11, 1, 248, 132, 184, 64, 198, 42, 55, 37, 192, 126, 199, 229, 22, 222,
                 103, 86, 51, 29, 17, 238, 229, 17, 124, 160, 247, 28, 39, 30, 186, 138, 206, 3,
                 179, 46, 224, 25, 32, 48, 25, 220, 61, 218, 161, 170, 122, 123, 30, 8, 122, 62,
                 232, 246, 47, 128, 64, 151, 153, 128, 69, 221, 3, 174, 6, 148, 197, 125, 192, 15,
                 184, 64, 33, 185, 19, 26, 171, 135, 138, 163, 121, 250, 122, 152, 34, 168, 11,
                 254, 89, 49, 219, 158, 93, 207, 98, 1, 229, 10, 163, 193, 8, 10, 81, 82, 239, 13,
                 219, 133, 175, 134, 76, 195, 134, 43, 166, 76, 59, 36, 53, 83, 120, 238, 252,
                 229, 166, 219, 165, 153, 61, 214, 128, 86, 52, 137, 51, 14, 184, 72, 248, 70, 57,
                 2, 161, 6, 245, 169, 216, 57, 28, 40, 9, 221, 141, 60, 227, 220, 162, 91, 220,
                 255, 107, 28, 150, 170, 195, 164, 93, 50, 116, 244, 179, 80, 127, 154, 153, 182,
                 43, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 43>>
             )

    {:ok, %{state_hash: state_hash_snapshot}} = Channel.get_by_pubkey(client6, channel_id)
    assert state_hash_create != state_hash_snapshot
  end
end
