defmodule Utils.Serialization do
  @moduledoc """
  false
  """

  @tag_signed_tx 11
  @tag_spend_tx 12
  @tag_oracle_register_tx 22
  @tag_oracle_query_tx 23
  @tag_oracle_response_tx 24
  @tag_oracle_extend_tx 25
  @tag_name_claim_tx 32
  @tag_name_preclaim_tx 33
  @tag_name_update_tx 34
  @tag_name_revoke_tx 35
  @tag_name_transfer_tx 36
  @tag_contract_create_tx 42
  @tag_contract_call_tx 43

  @version_signed_tx 1
  @version_spend_tx 1
  @version_oracle_register_tx 1
  @version_oracle_query_tx 1
  @version_oracle_response_tx 1
  @version_oracle_extend_tx 1
  @version_name_claim_tx 1
  @version_name_preclaim_tx 1
  @version_name_update_tx 1
  @version_name_revoke_tx 1
  @version_name_transfer_tx 1
  @version_contract_create_tx 1
  @version_contract_call_tx 1

  @type structure_type ::
          :signed_tx
          | :spend_tx
          | :oracle_register_tx
          | :oracle_query_tx
          | :oracle_extend_tx
          | :name_claim_tx
          | :name_preclaim_tx
          | :name_update_tx
          | :name_revoke_tx
          | :name_transfer_tx
          | :contract_create_tx
          | :contract_call_tx

  @type id :: {:id, id_type(), binary()}
  @type id_type :: :account | :oracle | :name | :commitment | :contract | :channel

  @type rlp_binary :: binary()

  @spec serialize(list(), structure_type()) :: rlp_binary()
  def serialize(fields, type) do
    template = serialization_template(type)
    fields_with_keys = set_keys(fields, template, [])
    tag = type_to_tag(type)
    version = version(type)
    :aeserialization.serialize(tag, version, template, fields_with_keys)
  end

  # this is the way the id record is represented in erlang
  @spec id_to_record(binary(), id_type()) :: id()
  def id_to_record(value, type), do: {:id, type, value}

  defp set_keys([field | rest_fields], [{key, _type} | rest_template], fields_with_keys),
    do: set_keys(rest_fields, rest_template, [{key, field} | fields_with_keys])

  defp set_keys([], [], fields_with_keys), do: Enum.reverse(fields_with_keys)

  defp serialization_template(:signed_tx) do
    [
      signatures: [:binary],
      transaction: :binary
    ]
  end

  defp serialization_template(:spend_tx) do
    [
      sender_id: :id,
      recipient_id: :id,
      amount: :int,
      fee: :int,
      ttl: :int,
      nonce: :int,
      payload: :binary
    ]
  end

  defp serialization_template(:oracle_register_tx) do
    [
      account_id: :id,
      nonce: :int,
      query_format: :binary,
      response_format: :binary,
      query_fee: :int,
      ttl_type: :int,
      ttl_value: :int,
      fee: :int,
      ttl: :int,
      abi_version: :int
    ]
  end

  defp serialization_template(:oracle_query_tx) do
    [
      sender_id: :id,
      nonce: :int,
      oracle_id: :id,
      query: :binary,
      query_fee: :int,
      query_ttl_type: :int,
      query_ttl_value: :int,
      response_ttl_type: :int,
      response_ttl_value: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:oracle_response_tx) do
    [
      oracle_id: :id,
      nonce: :int,
      query_id: :binary,
      response: :binary,
      response_ttl_type: :int,
      response_ttl_value: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:oracle_extend_tx) do
    [
      oracle_id: :id,
      nonce: :int,
      oracle_ttl_type: :int,
      oracle_ttl_value: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:name_claim_tx) do
    [account_id: :id, nonce: :int, name: :binary, name_salt: :int, fee: :int, ttl: :int]
  end

  defp serialization_template(:name_preclaim_tx) do
    [account_id: :id, nonce: :int, commitment_id: :id, fee: :int, ttl: :int]
  end

  defp serialization_template(:name_update_tx) do
    [
      account_id: :id,
      nonce: :int,
      name_id: :id,
      name_ttl: :int,
      pointers: [{:binary, :id}],
      client_ttl: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:name_revoke_tx) do
    [account_id: :id, nonce: :int, name_id: :id, fee: :int, ttl: :int]
  end

  defp serialization_template(:name_transfer_tx) do
    [account_id: :id, nonce: :int, name_id: :id, recipient_id: :id, fee: :int, ttl: :int]
  end

  defp serialization_template(:contract_create_tx) do
    [
      owner_id: :id,
      nonce: :int,
      code: :binary,
      ct_version: :int,
      fee: :int,
      ttl: :int,
      deposit: :int,
      amount: :int,
      gas: :int,
      gas_price: :int,
      call_data: :binary
    ]
  end

  defp serialization_template(:contract_call_tx) do
    [
      caller_id: :id,
      nonce: :int,
      contract_id: :id,
      abi_version: :int,
      fee: :int,
      ttl: :int,
      amount: :int,
      gas: :int,
      gas_price: :int,
      call_data: :binary
    ]
  end

  defp type_to_tag(:signed_tx), do: @tag_signed_tx
  defp type_to_tag(:spend_tx), do: @tag_spend_tx
  defp type_to_tag(:oracle_register_tx), do: @tag_oracle_register_tx
  defp type_to_tag(:oracle_query_tx), do: @tag_oracle_query_tx
  defp type_to_tag(:oracle_response_tx), do: @tag_oracle_response_tx
  defp type_to_tag(:oracle_extend_tx), do: @tag_oracle_extend_tx
  defp type_to_tag(:name_claim_tx), do: @tag_name_claim_tx
  defp type_to_tag(:name_preclaim_tx), do: @tag_name_preclaim_tx
  defp type_to_tag(:name_update_tx), do: @tag_name_update_tx
  defp type_to_tag(:name_revoke_tx), do: @tag_name_revoke_tx
  defp type_to_tag(:name_transfer_tx), do: @tag_name_transfer_tx
  defp type_to_tag(:contract_create_tx), do: @tag_contract_create_tx
  defp type_to_tag(:contract_call_tx), do: @tag_contract_call_tx

  defp version(:signed_tx), do: @version_signed_tx
  defp version(:spend_tx), do: @version_spend_tx
  defp version(:oracle_register_tx), do: @version_oracle_register_tx
  defp version(:oracle_query_tx), do: @version_oracle_query_tx
  defp version(:oracle_response_tx), do: @version_oracle_response_tx
  defp version(:oracle_extend_tx), do: @version_oracle_extend_tx
  defp version(:name_claim_tx), do: @version_name_claim_tx
  defp version(:name_preclaim_tx), do: @version_name_preclaim_tx
  defp version(:name_update_tx), do: @version_name_update_tx
  defp version(:name_revoke_tx), do: @version_name_revoke_tx
  defp version(:name_transfer_tx), do: @version_name_transfer_tx
  defp version(:contract_create_tx), do: @version_contract_create_tx
  defp version(:contract_call_tx), do: @version_contract_call_tx
end
