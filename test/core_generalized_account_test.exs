defmodule CoreGeneralizedAccountTest do
  use ExUnit.Case

  alias AeppSDK.{Account, GeneralizedAccount}

  setup_all do
    Code.require_file("test_utils.ex", "test/")
    TestUtils.get_test_data()
  end

  @tag :travis_test
  test "attach and spend with auth, attempt to spend with failing auth", setup_data do
    {:ok, _} =
      Account.spend(
        setup_data.client,
        setup_data.auth_client.keypair.public,
        100_000_000_000_000_000
      )

    assert match?(
             {:error, "Account isn't generalized"},
             Account.spend(setup_data.auth_client, setup_data.client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code_auth_client,
                 auth_args: ["true"],
                 fee: 100_000_000_000_000
               ]
             )
           )

    assert match?(
             {:ok, _},
             GeneralizedAccount.attach(
               setup_data.auth_client,
               setup_data.source_code_auth_client,
               "auth",
               []
             )
           )

    assert match?(
             {:ok, _},
             Account.spend(setup_data.auth_client, setup_data.client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code_auth_client,
                 auth_args: ["true"],
                 fee: 100_000_000_000_000
               ]
             )
           )

    assert match?(
             {:error, _},
             Account.spend(setup_data.auth_client, setup_data.client.keypair.public, 100,
               auth: [
                 auth_contract_source: setup_data.source_code_auth_client,
                 auth_args: ["false"],
                 fee: 100_000_000_000_000
               ]
             )
           )
  end
end
