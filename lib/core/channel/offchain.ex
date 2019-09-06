defmodule AeppSDK.Channel.OffChain do
  # 2 is a supported version, as we support generalized accounts, 1 is without meta data support
  @update_vsn 2
  @transfer_fields_template [from_id: :id, to_id: :id, amount: :id]
  @deposit_fields_template [from_id: :id, amount: :int]
  @withdraw_fields_template [to_id: :id, amount: :int]
  @create_contract_fields_template [
    owner_id: :id,
    ct_version: :int,
    code: :binary,
    deposit: :int,
    call_data: :binary
  ]
  @call_contract_fields_template [
    caller_id: :id,
    contract_id: :id,
    abi_version: :int,
    amount: :int,
    gas: :int,
    gas_price: :int,
    call_data: :binary,
    call_stack: [:int]
  ]
  @meta_fields_template [data: :binary]

  defstruct channel_id: <<>>, round: 0, state_hash: <<>>, updates: []

  def new(<<"ch_", _channel_id>> = channel_id, round, state_hash, updates \\ []) do
  end

  def serialize_updates(update) do
    serialize_update(update, [])
  end

  defp serialize_update([], acc) do
    acc
  end

  defp serialize_update(
         [
           %{type: :transfer, from_id: _from_id, to_id: _to_id, amount: _amount} = update
           | updates
         ],
         acc
       ) do
    template = @transfer_fields_template
    fields = prepare_fields(update, template)

    serialized_update =
      :aeser_chain_objects.serialize(
        :channel_offchain_update_transfer,
        @update_vsn,
        template,
        fields
      )

    serialize_update(updates, [acc | serialized_update])
  end

  defp serialize_update(
         [%{type: :withdraw, to_id: _to_id, amount: _amount} = update | updates],
         acc
       ) do
    template = @withdraw_fields_template
    fields = prepare_fields(update, template)

    serialized_update =
      :aeser_chain_objects.serialize(
        :channel_offchain_update_withdraw,
        @update_vsn,
        template,
        fields
      )

    serialize_update(updates, [acc | serialized_update])
  end

  defp serialize_update(
         [%{type: :deposit, from_id: _from_id, amount: _amount} = update | updates],
         acc
       ) do
    template = @deposit_fields_template
    fields = prepare_fields(update, template)

    serialized_update =
      :aeser_chain_objects.serialize(
        :channel_offchain_update_deposit,
        @update_vsn,
        template,
        fields
      )

    serialize_update(updates, [acc | serialized_update])
  end

  defp serialize_update(
         [
           %{
             type: :create_contract,
             owner_id: _owner_id,
             ct_version: _ct_version,
             code: _code,
             deposit: _deposit,
             call_data: _call_data
           } = update
           | updates
         ],
         acc
       ) do
    template = @create_contract_fields_template
    fields = prepare_fields(update, template)

    serialized_update =
      :aeser_chain_objects.serialize(
        :channel_offchain_update_create_contract,
        @update_vsn,
        template,
        fields
      )

    serialize_update(updates, [acc | serialized_update])
  end

  defp serialize_update(
         [
           %{
             type: :call_contract,
             caller_id: _caller_id,
             contract_id: _contract_id,
             abi_version: _abi_version,
             amount: _amount,
             call_data: _call_data,
             call_stack: _call_stack,
             gas_price: _gas_price,
             gas: _gas
           } = update
           | updates
         ],
         acc
       ) do
    template = @call_contract_fields_template
    fields = prepare_fields(update, template)

    serialized_update =
      :aeser_chain_objects.serialize(
        :channel_offchain_update_call_contract,
        @update_vsn,
        template,
        fields
      )

    serialize_update(updates, [acc | serialized_update])
  end

  defp serialize_update([%{type: :meta} = update | updates], acc) do
    template = @meta_fields_template
    fields = prepare_fields(update, template)
    # last step of serializations, should be put in accumulator

    serialized_update =
      :aeser_chain_objects.serialize(:channel_offchain_update_meta, @update_vsn, template, fields)

    serialize_update(fields, [acc | serialized_update])
  end

  defp prepare_fields(update, template) do
    for {field, _type} <- template do
      {field, Map.get(update, field)}
    end
  end
end
