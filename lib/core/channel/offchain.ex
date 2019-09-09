defmodule AeppSDK.Channel.OffChain do
  # 2 is a supported version, as we support generalized accounts, 1 is without meta data support
  @update_vsn 2
  @transfer_fields_template [from: :id, to: :id, amount: :int]
  @deposit_fields_template [from: :id, amount: :int]
  @withdraw_fields_template [to: :id, amount: :int]
  @create_contract_fields_template [
    owner: :id,
    ct_version: :int,
    code: :binary,
    deposit: :int,
    call_data: :binary
  ]
  @call_contract_fields_template [
    caller: :id,
    contract: :id,
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

  def serialize_updates(update) when is_list(update) do
    serialize_update(update, [])
  end

  # TODO should be handled better than it is now
  def serialize_updates(%{type: _} = valid_update_struct) do
    serialize_update([valid_update_struct], [])
  end

  defp serialize_update([], acc) do
    acc
  end

  # TODO maybe remove strict matching on identified binaries

  defp serialize_update(
         [
           %{
             type: :transfer,
             from: {:id, :account, _from_id},
             to: {:id, :account, _to_id},
             amount: _amount
           } = update
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

    serialize_update(updates, [serialized_update | acc])
  end

  defp serialize_update(
         [
           %{type: :withdraw, to: {:id, :account, _account_id}, amount: _amount} = update
           | updates
         ],
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

    serialize_update(updates, [serialized_update | acc])
  end

  defp serialize_update(
         [
           %{type: :deposit, from: {:id, :account, _caller_id}, amount: _amount} = update
           | updates
         ],
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

    serialize_update(updates, [serialized_update | acc])
  end

  defp serialize_update(
         [
           # TODO: maybe type of contract identifier is also/only a possible entity?
           %{
             type: :create_contract,
             owner_id: {:id, :account, _owner_id},
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

    serialize_update(updates, [serialized_update | acc])
  end

  defp serialize_update(
         [
           # TODO: who are exactly callers? can oracle/other contract entity also call the contract?
           %{
             type: :call_contract,
             caller: {:id, :account, _caller_id},
             contract: {:id, :contract, _contract_id},
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

    serialize_update(updates, [serialized_update | acc])
  end

  defp serialize_update([%{type: :meta} = update | updates], acc) do
    template = @meta_fields_template
    fields = prepare_fields(update, template)
    # last step of serializations, should be put in accumulator

    serialized_update =
      :aeser_chain_objects.serialize(:channel_offchain_update_meta, @update_vsn, template, fields)

    serialize_update(updates, [serialized_update | acc])
  end

  defp prepare_fields(update, template) do
    for {field, _type} <- template do
      {field, Map.get(update, field)}
    end
  end
end
