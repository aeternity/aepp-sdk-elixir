defmodule Core.GeneralizedAccounts do
  @moduledoc """
  Contains all generalized accounts functionalities.

  In order for its functions to be used, a client must be defined first.
  Client example can be found at: `Core.Client.new/4`.

  For more information: https://github.com/aeternity/protocol/blob/master/generalized_accounts/generalized_accounts.md
  """

  alias Utils.{Hash, Serialization}
  alias AeternityNode.Api.Chain, as: ChainApi
  alias Utils.Account, as: AccountUtils

  alias Utils.Transaction
  alias Core.{Client, Contract}

  @ct_version 0x40001
  @init_function "init"

  def attach(
        %Client{
          keypair: %{public: public_key},
          connection: connection
        } = client,
        source_code,
        auth_fun,
        init_args,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, public_key),
         {:ok, %{byte_code: byte_code, type_info: type_info}} <-
           Contract.compile(source_code),
         {:ok, function_hash} <- :aeb_abi.type_hash_from_function_name(auth_fun, type_info),
         {:ok, calldata} <- Contract.create_calldata(source_code, @init_function, init_args),
         {:ok, source_hash} <- Hash.hash(source_code),
         byte_code_fields = [
           source_hash,
           type_info,
           byte_code
         ],
         serialized_wrapped_code = Serialization.serialize(byte_code_fields, :sophia_byte_code),
         ga_attach_tx = %{
           owner_id: public_key,
           nonce: nonce,
           code: serialized_wrapped_code,
           auth_fun: function_hash,
           ct_version: @ct_version,
           fee: Keyword.get(opts, :fee, 0),
           ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
           gas: Keyword.get(opts, :gas, Contract.default_gas()),
           gas_price: Keyword.get(opts, :gas_price, Contract.default_gas_price()),
           call_data: calldata
         },
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection),
         {:ok, response} <-
           Transaction.try_post(
             client,
             ga_attach_tx,
             Keyword.get(opts, :auth, nil),
             height
           ) do
      response
    else
      e -> e
    end
  end
end
