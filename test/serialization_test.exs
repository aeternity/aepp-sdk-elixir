defmodule UtilsSerializationTest do
  use ExUnit.Case

  alias AeppSDK.Utils.Serialization

  setup_all do
    Code.require_file("test_utils.ex", "test/")
    TestUtils.get_test_data()
  end

  test "serialization of valid fields doesn't raise error", fields do
    Serialization.serialize(fields.spend_fields, :spend_tx)
    Serialization.serialize(fields.oracle_register_fields, :oracle_register_tx)
    Serialization.serialize(fields.oracle_query_fields, :oracle_query_tx)
    Serialization.serialize(fields.oracle_response_fields, :oracle_response_tx)
    Serialization.serialize(fields.oracle_extend_fields, :oracle_extend_tx)
    Serialization.serialize(fields.name_claim_fields, :name_claim_tx)
    Serialization.serialize(fields.name_preclaim_fields, :name_preclaim_tx)
    Serialization.serialize(fields.name_update_fields, :name_update_tx)
    Serialization.serialize(fields.name_revoke_fields, :name_revoke_tx)
    Serialization.serialize(fields.name_transfer_fields, :name_transfer_tx)
    Serialization.serialize(fields.contract_create_fields, :contract_create_tx)
    Serialization.serialize(fields.contract_call_fields, :contract_call_tx)
  end

  test "serialization of invalid fields raises error", fields do
    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :sender_id, :id, \"invalid account\", :id, \"invalid account\"}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.spend_fields, 0, "invalid account"),
                     :spend_tx
                   )
                 end

    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :amount, :int, \"invalid amount\", :int, \"invalid amount\"}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.spend_fields, 2, "invalid amount"),
                     :spend_tx
                   )
                 end

    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :payload, :binary, 0, :binary, 0}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.spend_fields, 6, 0),
                     :spend_tx
                   )
                 end

    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :pointers, [binary: :id], [{1, 2}, {\"a\", \"b\"}], :binary, 1}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.name_update_fields, 4, [{1, 2}, {"a", "b"}]),
                     :name_update_tx
                   )
                 end
  end

  test "valid serialization of transactions", fields do
    Serialization.serialize(fields.spend_tx)
    Serialization.serialize(fields.oracle_register_tx)
    Serialization.serialize(fields.oracle_respond_tx)
    Serialization.serialize(fields.oracle_query_tx)
    Serialization.serialize(fields.oracle_extend_tx)
    Serialization.serialize(fields.name_pre_claim_tx)
    Serialization.serialize(fields.name_claim_tx)
    Serialization.serialize(fields.name_revoke_tx)
    Serialization.serialize(fields.name_update_tx)
    Serialization.serialize(fields.name_transfer_tx)
    Serialization.serialize(fields.contract_create_tx)
    Serialization.serialize(fields.contract_call_tx)
  end
end
