defmodule Core.NamingTest do
  use ExUnit.Case
  alias Utils.{Keys, Serialization}
  alias Core.{AENS, Account}

  setup_all do
    Code.require_file("test_utils.ex", "../utils/test")
    TestUtils.get_test_data()
  end

  @tag :travis_test
  test "test naming workflow", setup do
    # Pre-claim a name
    pre_claim = AENS.preclaim(setup.client, "test.test", 777)
    assert match?({:ok, _}, pre_claim)
    # We need to wait a bit
    Process.sleep(1000)
    # Claim a name
    claim = AENS.claim(setup.client, "test.test", 777)
    assert match?({:ok, _}, claim)
    Process.sleep(1000)
    # Update a name

    list_of_pointers = [
      {Utils.Keys.public_key_to_binary(setup.valid_pub_key),
       Serialization.id_to_record(
         Keys.public_key_to_binary(setup.valid_pub_key),
         :account
       )}
    ]

    update =
      AENS.update_name(
        setup.client,
        "test.test",
        49_999,
        list_of_pointers,
        50_000
      )

    assert match?({:ok, _}, update)
    # Spending to another account, in order to transfer a name to it
    spend =
      Account.spend(
        %{setup.client | gas_price: 1_000_000_000_000},
        setup.valid_pub_key,
        setup.amount
      )

    assert match?({:ok, _}, spend)

    # Transfer a name to another account
    transfer = AENS.transfer_name(setup.client, "test.test", setup.valid_pub_key)

    assert match?({:ok, _}, transfer)
    Process.sleep(1000)

    # Pre-claim a new name
    pre_claim = AENS.preclaim(setup.client, "newtest.test", 888)
    assert match?({:ok, _}, pre_claim)
    # We need to wait a bit
    Process.sleep(1000)
    # Claim a new name
    claim = AENS.claim(setup.client, "newtest.test", 888)
    assert match?({:ok, _}, claim)
    Process.sleep(1000)

    # Revoke a new name
    revoke = AENS.revoke_name(setup.client, "newtest.test")
    assert match?({:ok, _}, revoke)
  end
end
