defmodule CoreGeneralizedAccountTest do
  use ExUnit.Case

  alias Core.{Account, GeneralizedAccount, Client}

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

    source_code = "contract Authorization =

      function auth(auth_value : bool) =
        auth_value"

    [client: client, source_code: source_code]
  end

  @tag :travis_test
  test "attach and spend with auth, attempt to spend with failing auth", setup_data do
    assert match?(
             {:error, "Account isn't generalized"},
             Account.spend(setup_data.client, setup_data.client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code,
                 auth_args: ["true"],
                 fee: 1_000_000_000_000_00
               ]
             )
           )

    assert match?(
             {:ok, _},
             GeneralizedAccount.attach(
               setup_data.client,
               setup_data.source_code,
               "auth",
               []
             )
           )

    assert match?(
             {:ok, _},
             Account.spend(setup_data.client, setup_data.client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code,
                 auth_args: ["true"],
                 fee: 1_000_000_000_000_00
               ]
             )
           )

    assert match?(
             {:error, _},
             Account.spend(setup_data.client, setup_data.client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code,
                 auth_args: ["false"],
                 fee: 1_000_000_000_000_00
               ]
             )
           )
  end
end
