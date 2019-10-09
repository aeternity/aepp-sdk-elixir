defmodule CoreGeneralizedAccountTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Client, GeneralizedAccount}

  setup_all do
    spend_client =
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

    auth_keypair = %{
      public: "ak_wuLXPE5pd2rvFoxHxvenBgp459rW6Y1cZ6cYTZcAcLAevPE5M",
      secret:
        "799ef7aa9ed8e3d58cd2492b7a569ccf967f3b63dc49ac2d0c9ea916d29cf8387ca99a8cd824b2a3efc3c6c5d500585713430575d4ce6999b202cb20f86019d8"
    }

    auth_client = %Client{spend_client | keypair: auth_keypair}

    source_code = "contract Authorization =

      entrypoint auth(auth_value : bool) =
        auth_value"

    [spend_client: spend_client, auth_client: auth_client, source_code: source_code]
  end

  @tag :travis_test
  test "attach and spend with auth, attempt to spend with failing auth", setup_data do
    {:ok, _} =
      Account.spend(
        setup_data.spend_client,
        setup_data.auth_client.keypair.public,
        100_000_000_000_000_000
      )

    assert match?(
             {:error, "Account isn't generalized"},
             Account.spend(setup_data.auth_client, setup_data.spend_client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code,
                 auth_args: ["true"],
                 fee: 100_000_000_000_000
               ]
             )
           )

    assert match?(
             {:ok, _},
             GeneralizedAccount.attach(
               setup_data.auth_client,
               setup_data.source_code,
               "auth",
               []
             )
           )

    assert match?(
             {:ok, _},
             Account.spend(setup_data.auth_client, setup_data.spend_client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code,
                 auth_args: ["true"],
                 fee: 100_000_000_000_000
               ]
             )
           )

    assert match?(
             {:error, _},
             Account.spend(setup_data.auth_client, setup_data.spend_client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code,
                 auth_args: ["false"],
                 fee: 100_000_000_000_000
               ]
             )
           )
  end
end
