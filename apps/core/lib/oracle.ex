defmodule Core.Oracle do
  alias Utils.Transaction, as: TransactionUtils
  alias Utils.Account, as: AccountUtils
  alias Core.Client
  alias AeternityNode.Model.{GenericSignedTx, OracleRegisterTx, Ttl}
  alias AeternityNode.Model.InlineResponse2001, as: HeightResponse
  alias AeternityNode.Api.Chain, as: ChainApi

  @abi_version 0x01
  @ttl_types [:relative, :absolute]

  def register(
        %Client{
          keypair: %{public: pubkey, secret: privkey},
          network_id: network_id,
          connection: connection
        },
        query_format,
        response_format,
        ttl_type,
        ttl_value,
        query_fee,
        opts \\ []
      )
      when is_binary(query_format) and is_binary(response_format) and ttl_type in @ttl_types and
             ttl_value > 0 and is_integer(query_fee) and query_fee > 0 do
    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         {:ok, binary_query_format} <- sophia_type_to_binary(query_format),
         {:ok, binary_response_format} <- sophia_type_to_binary(response_format),
         tx_dummy_fee = %OracleRegisterTx{
           query_format: binary_query_format,
           response_format: binary_response_format,
           query_fee: query_fee,
           oracle_ttl: %Ttl{type: ttl_type, value: ttl_value},
           account_id: pubkey,
           nonce: nonce,
           fee: 0,
           ttl: Keyword.get(opts, :ttl, TransactionUtils.default_ttl()),
           vm_version: :unused,
           abi_version: @abi_version
         },
         {:ok, %HeightResponse{height: height}} <-
           ChainApi.get_current_key_block_height(connection),
         tx = %{
           tx_dummy_fee
           | fee:
               Keyword.get(
                 opts,
                 :fee,
                 TransactionUtils.calculate_min_fee(tx_dummy_fee, height, network_id) * 100_000
               )
         },
         {:ok, %GenericSignedTx{}} <-
           TransactionUtils.post(
             connection,
             privkey,
             network_id,
             tx
           ) do
      {:ok, String.replace_prefix(pubkey, "ak", "ok")}
    else
      {:error, _} = error ->
        error
    end
  end

  defp sophia_type_to_binary(type) do
    case type |> String.to_charlist() |> :aeso_compiler.sophia_type_to_typerep() do
      {:ok, typerep} ->
        {:ok, :aeb_heap.to_binary(typerep)}

      {:error, _} ->
        {:error, "Bad Sophia type: #{type}"}
    end
  end
end
