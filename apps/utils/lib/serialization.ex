defmodule Utils.Serialization do
  @moduledoc """
  Transaction serialization
  """
  alias Utils.SerializationUtils

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
  @tag_sophia_byte_code 70

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
  @version_sophia_byte_code 1

  @type structure_type ::
          :signed_tx
          | :spend_tx
          | :oracle_register_tx
          | :oracle_query_tx
          | :oracle_response_tx
          | :oracle_extend_tx
          | :name_claim_tx
          | :name_preclaim_tx
          | :name_update_tx
          | :name_revoke_tx
          | :name_transfer_tx
          | :contract_create_tx
          | :contract_call_tx
          | :sophia_byte_code

  @type tx_type ::
          AeternityNode.Model.SpendTx.t()
          | AeternityNode.Model.OracleRegisterTx.t()
          | AeternityNode.Model.OracleRespondTx.t()
          | AeternityNode.Model.OracleQueryTx.t()
          | AeternityNode.Model.OracleExtendTx.t()
          | AeternityNode.Model.NamePreclaimTx.t()
          | AeternityNode.Model.NameClaimTx.t()
          | AeternityNode.Model.NameRevokeTx.t()
          | AeternityNode.Model.NameTransferTx.t()
          | AeternityNode.Model.NameUpdateTx.t()
          | AeternityNode.Model.ContractCreateTx.t()
          | AeternityNode.Model.ContractCallTx.t()

  @type id :: {:id, id_type(), binary()}
  @type id_type :: :account | :oracle | :name | :commitment | :contract | :channel

  @type rlp_binary :: binary()

  @doc """
  Serializes a list of fields with the template corresponding to the given type

  ## Examples
      iex> fields = [{:id, :account,
      <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
        91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>},
     8579,
     {:id, :contract,
      <<64, 216, 143, 81, 41, 52, 245, 89, 135, 253, 7, 12, 94, 142, 96, 251, 212,
        96, 76, 248, 1, 152, 97, 16, 144, 62, 43, 186, 148, 174, 76, 114>>},
     1,
     2000000000000000000,
     0,
     0,
     1000000,
     1000000000,
     <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 32, 112, 194, 27, 63, 171, 248, 210, 119, 144, 238, 34,
       30, 100, 222, 2, 111, 12, 11, 11, 82, 86, 82, 53, 206, 145, 155, 60, 13,
       206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33>>]
      iex> type = :contract_call_tx
      iex> Utils.Serialization.serialize(fields, type)
      <<248, 224, 43, 1, 161, 1, 11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181,
      225, 52, 13, 18, 51, 91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57,
      212, 30, 97, 130, 33, 131, 161, 5, 64, 216, 143, 81, 41, 52, 245, 89, 135,
      253, 7, 12, 94, 142, 96, 251, 212, 96, 76, 248, 1, 152, 97, 16, 144, 62, 43,
      186, 148, 174, 76, 114, 1, 136, 27, 193, 109, 103, 78, 200, 0, 0, 0, 0, 131,
      15, 66, 64, 132, 59, 154, 202, 0, 184, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 112, 194, 27,
      63, 171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82,
      86, 82, 53, 206, 145, 155, 60, 13, 206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 33>>
  """
  @spec serialize(list(), structure_type()) :: rlp_binary()
  def serialize(fields, type) when is_list(fields) do
    process_serialize(fields, type)
  end

  @doc """
  Serializes a transaction to a binary.

  ## Examples
      iex> alias AeternityNode.Model.{Ttl,OracleRegisterTx}
      iex> Utils.Serialization.serialize( %OracleRegisterTx{
           query_format: <<"query_format">>,
           response_format: <<"response_format">>,
           query_fee: 10,
           oracle_ttl: %Ttl{type: "block", value: 10},
           account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
           nonce: 37122,
           fee: 0,
           ttl: 10,
           vm_version: 0x30001,
           abi_version: 0x30001
         })
       <<248, 77, 22, 1, 161, 1, 9, 51, 126, 98, 138, 255, 218, 224, 184, 180, 31, 234,
        251, 255, 59, 141, 224, 214, 250, 79, 248, 30, 246, 237, 55, 83, 153, 134,
        240, 138, 216, 129, 130, 145, 2, 140, 113, 117, 101, 114, 121, 95, 102, 111,
        ...>>
  """
  @spec serialize(tx_type()) :: rlp_binary()
  def serialize(tx) do
    {:ok, fields, type} = SerializationUtils.process_tx_fields(tx)
    process_serialize(fields, type)
  end

  @doc """
  Deserialize an RLP binary payload with the template corresponding to the given type

  ## Examples
      iex> payload = <<248, 224, 43, 1, 161, 1, 11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181,
          225, 52, 13, 18, 51, 91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57,
          212, 30, 97, 130, 33, 131, 161, 5, 64, 216, 143, 81, 41, 52, 245, 89, 135,
          253, 7, 12, 94, 142, 96, 251, 212, 96, 76, 248, 1, 152, 97, 16, 144, 62, 43,
          186, 148, 174, 76, 114, 1, 136, 27, 193, 109, 103, 78, 200, 0, 0, 0, 0, 131,
          15, 66, 64, 132, 59, 154, 202, 0, 184, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 112, 194, 27,
          63, 171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82,
          86, 82, 53, 206, 145, 155, 60, 13, 206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 33>>
      iex> type = :contract_call_tx
      iex> Utils.Serialization.deserialize(payload, type)
      [
        caller_id: {:id, :account,
         <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
           91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>},
        nonce: 8579,
        contract_id: {:id, :contract,
         <<64, 216, 143, 81, 41, 52, 245, 89, 135, 253, 7, 12, 94, 142, 96, 251, 212,
           96, 76, 248, 1, 152, 97, 16, 144, 62, 43, 186, 148, 174, 76, 114>>},
        abi_version: 1,
        fee: 2000000000000000000,
        ttl: 0,
        amount: 0,
        gas: 1000000,
        gas_price: 1000000000,
        call_data: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 112, 194, 27, 63, 171, 248, 210, 119, 144,
          238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82, 86, 82, 53, 206, 145, 155,
          60, 13, 206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33>>
      ]
  """
  @spec deserialize(binary(), structure_type()) :: list()
  def deserialize(payload, type) do
    template = serialization_template(type)
    tag = type_to_tag(type)
    version = version(type)

    :aeserialization.deserialize(:sophia_byte_code, tag, version, template, payload)
  end

  # this is the way the id record is represented in erlang
  @spec id_to_record(binary(), id_type()) :: id()
  def id_to_record(value, type)
      when type in [:account, :oracle, :name, :commitment, :contract, :channel],
      do: {:id, type, value}

  defp process_serialize(fields, type) do
    template = serialization_template(type)
    fields_with_keys = set_keys(fields, template, [])
    tag = type_to_tag(type)
    version = version(type)

    :aeserialization.serialize(tag, version, template, fields_with_keys)
  end

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

  defp serialization_template(:sophia_byte_code) do
    [
      source_code_hash: :binary,
      type_info: [{:binary, :binary, :binary, :binary}],
      byte_code: :binary
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
  defp type_to_tag(:sophia_byte_code), do: @tag_sophia_byte_code

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
  defp version(:sophia_byte_code), do: @version_sophia_byte_code
end
