defmodule TransactionUtilTest do
  use ExUnit.Case

  alias Utils.Transaction
  alias Core.Account

  setup_all do
    Code.require_file("test_utils.ex", "./test")
    TestUtils.get_test_data()
  end

  test "minimum fee calculation", fields do
    assert 16_740_000_000 == Transaction.calculate_min_fee(fields.spend_tx, 50_000, "ae_mainnet")
    assert 16581 == Transaction.calculate_min_fee(fields.oracle_register_tx, 5, "ae_mainnet")

    assert 16_842_000_000 ==
             Transaction.calculate_min_fee(fields.oracle_respond_tx, 50_000, "ae_mainnet")

    assert 16_722_000_000 ==
             Transaction.calculate_min_fee(fields.oracle_query_tx, 50_000, "ae_mainnet")

    assert 15_842_000_000 ==
             Transaction.calculate_min_fee(fields.oracle_extend_tx, 50_000, "ae_mainnet")

    assert 16_500_000_000 ==
             Transaction.calculate_min_fee(fields.name_pre_claim_tx, 50_000, "ae_mainnet")

    assert 16_900_000_000 ==
             Transaction.calculate_min_fee(fields.name_claim_tx, 50_000, "ae_mainnet")

    assert 16_500_000_000 ==
             Transaction.calculate_min_fee(fields.name_revoke_tx, 50_000, "ae_mainnet")

    assert 16_560_000_000 ==
             Transaction.calculate_min_fee(fields.name_update_tx, 50_000, "ae_mainnet")

    assert 17_180_000_000 ==
             Transaction.calculate_min_fee(fields.name_transfer_tx, 50_000, "ae_mainnet")

    assert 80_400_000_000 ==
             Transaction.calculate_min_fee(fields.contract_create_tx, 50_000, "ae_mainnet")

    assert 451_880_000_000 ==
             Transaction.calculate_min_fee(fields.contract_call_tx, 50_000, "ae_mainnet")
  end

  @tag :travis_test
  test "post valid spend transaction", fields do
    assert match?(
             {:ok, %{}},
             Account.spend(
               fields.client,
               fields.valid_pub_key,
               fields.amount
             )
           )
  end

  @tag :travis_test
  test "post valid spend transaction by given gas price", fields do
    assert {:ok, %{}} =
             Account.spend(
               %{fields.client | gas_price: 1_000_000_000_000},
               fields.valid_pub_key,
               fields.amount
             )
  end
end
