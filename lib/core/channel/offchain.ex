defmodule AeppSDK.Channel.OffChain do
  @moduledoc """
  Module for Aeternity Off-chain channel activities, see: [https://github.com/aeternity/protocol/blob/master/channels/OFF-CHAIN.md](https://github.com/aeternity/protocol/blob/master/channels/OFF-CHAIN.md)
  Contains Off-Chain channel-related functionality.
  """
  alias AeppSDK.Utils.Serialization

  @update_vsn 1
  @updates_version 1
  @no_updates_version 2
  @meta_fields_template [data: :binary]
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

  @doc """
  Creates new off-chain transactions, supporting updates, with given parameters.

  ## Example

    iex> channel = "ch_11111111111111111111111111111111273Yts"
    iex> state_hash = "st_11111111111111111111111111111111273Yts"
    iex> AeppSDK.Channel.OffChain.new(channel, 1, state_hash, 1, [])
      %{
        channel_id: "ch_11111111111111111111111111111111273Yts",
        round: 1,
        state_hash: "st_11111111111111111111111111111111273Yts",
        updates: [],
        version: 1
      }
  """
  @spec new(String.t(), integer(), String.t(), integer(), list()) :: map()
  def new(
        <<"ch_", _channel_id::binary>> = channel_id,
        round,
        <<"st_", _state_hash::binary>> = encoded_state_hash,
        @updates_version,
        updates
      )
      when is_list(updates) do
    %{
      channel_id: channel_id,
      round: round,
      state_hash: encoded_state_hash,
      version: @updates_version,
      updates: serialize_updates(updates)
    }
  end

  @doc """
  Creates new off-chain transactions, without supporting updates, with given parameters.

  ## Example

    iex> channel = "ch_11111111111111111111111111111111273Yts"
    iex> state_hash = "st_11111111111111111111111111111111273Yts"
    iex> AeppSDK.Channel.OffChain.new(channel, 1, state_hash, 2)
      %{
        channel_id: "ch_11111111111111111111111111111111273Yts",
        round: 1,
        state_hash: "st_11111111111111111111111111111111273Yts",
        version: 2
      }
  """

  @spec new(String.t(), integer(), String.t(), integer()) :: map()
  def new(
        <<"ch_", _channel_id::binary>> = channel_id,
        round,
        <<"st_", _state_hash::binary>> = encoded_state_hash,
        @no_updates_version
      ) do
    %{
      channel_id: channel_id,
      round: round,
      version: @no_updates_version,
      state_hash: encoded_state_hash
    }
  end

  @doc """
  Serializes off-chain transactions, supports both updates and no-updates versions.

  ## Example

    iex> channel = "ch_11111111111111111111111111111111273Yts"
    iex> state_hash = "st_11111111111111111111111111111111273Yts"
    iex> channel_off_chain_tx = AeppSDK.Channel.OffChain.new(channel, 1, state_hash, 2)
    iex> AeppSDK.Channel.OffChain.serialize_tx(channel_off_chain_tx)
      <<248,70,57,2,161,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
      160,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0>>

  """
  @spec serialize_tx(map()) :: binary()
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

  @doc """
  Serializes off-chain updates.

  ## Example

    iex> update = %{type: :transfer, from: {:id, :account, <<0::256>>}, to: {:id, :account, <<0::256>>}, amount: 100}
    iex> AeppSDK.Channel.OffChain.serialize_updates(update)
      [<<248,73,130,2,58,1,161,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      161,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100>>]

  """
  @spec serialize_updates(list()) :: list(binary())
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
