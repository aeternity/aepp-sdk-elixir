defmodule Core.Oracle do
  alias Utils.{Keys, Serialization}
  alias Utils.Transaction, as: TransactionUtils
  alias Utils.Account, as: AccountUtils
  alias Core.Client
  alias AeternityNode.Model.ContractCallObject

  @abi_version 0x01

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
      ) do
    pubkey_binary = Keys.pubkey_to_binary(pubkey)
    owner_id = Serialization.id_to_record(pubkey_binary, :account)

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, pubkey),
         {:ok, int_ttl_type} <- ttl_type_to_int(ttl_type),
         oracle_register_fields = [
           owner_id,
           nonce,
           query_format,
           response_format,
           query_fee,
           int_ttl_type,
           ttl_value,
           Keyword.get(opts, :fee, TransactionUtils.calculate_min_fee()),
           Keyword.get(opts, :ttl, TransactionUtils.default_ttl()),
           @abi_version
         ],
         {:ok, %ContractCallObject{} = bla} <-
           TransactionUtils.post(
             connection,
             privkey,
             network_id,
             oracle_register_fields,
             :oracle_register_tx
           ) do
      bla
    else
      {:error, _} = error ->
        error
    end
  end

  defp ttl_type_to_int(ttl_type) do
    case ttl_type do
      :relative -> {:ok, 0}
      :fixed -> {:ok, 1}
      _ -> {:error, "Invalid TTL type"}
    end
  end
end
