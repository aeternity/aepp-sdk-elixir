defmodule AeppSDK.Channel.OffChain do
  alias AeppSDK.Utils.Serialization
  @updates_version 1
  @no_updates_version 2
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
  @update_vsn 1
  @meta_fields_template [data: :binary]

  defstruct channel_id: <<>>, round: 0, state_hash: <<>>, updates: []

  def new(
        <<"ch_", _channel_id>> = channel_id,
        round,
        <<"st_", _state_hash>> = encoded_state_hash,
        version,
        updates
      )
      when is_list(updates) and version == @updates_version do
    %{
      channel_id: channel_id,
      round: round,
      state_hash: encoded_state_hash,
      version: version,
      updates: serialize_updates(updates)
    }
  end

  def new(
        <<"ch_", _channel_id::binary>> = channel_id,
        round,
        <<"st_", _state_hash::binary>> = encoded_state_hash,
        version
      )
      when version == @no_updates_version do
    %{channel_id: channel_id, round: round, version: version, state_hash: encoded_state_hash}
  end

  def serialize_tx(
        %{
          channel_id: _channel_id,
          round: _round,
          state_hash: _state_hash,
          version: _version
        } = offchain_tx
      ) do
    Serialization.serialize(offchain_tx)
  end

  def serialize_updates(update) when is_list(update) do
    serialize_update(update, [])
  end

  def serialize_updates(%{type: _} = valid_update_struct) do
    serialize_update([valid_update_struct], [])
  end

  defp serialize_update([], acc) do
    acc
  end

  defp serialize_update(
         [
           %{
             type: :transfer,
             from: {:id, _, _from_id},
             to: {:id, _, _to_id},
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
           %{type: :withdraw, to: {:id, _, _account_id}, amount: _amount} = update
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
           %{type: :deposit, from: {:id, _, _caller_id}, amount: _amount} = update
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
           %{
             type: :create_contract,
             owner: {:id, _, _owner_id},
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
           %{
             type: :call_contract,
             caller: {:id, _, _caller_id},
             contract: {:id, _, _contract_id},
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
