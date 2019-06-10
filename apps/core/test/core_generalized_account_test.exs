defmodule CoreGeneralizedAccountTest do
  use ExUnit.Case

  alias Core.{Account, GeneralizedAccount, Client}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_2t22NBJRGK4EC7Rvp5f56rzVpmJmhBsP7qUuUf3EJUjt1yS29C",
          secret:
            "7c0bc9da525c33c24b3ff7bd439a1889e5b550e5688806091064e8e8c215881cf789b41a34b4e9381544a1f6eb04a8ae1a46ba968d74468446d5dae32462f163"
        },
        "ae_uat",
        "https://sdk-testnet.aepps.com/v2",
        "https://sdk-testnet.aepps.com/v2",
        1_000_000_000
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
