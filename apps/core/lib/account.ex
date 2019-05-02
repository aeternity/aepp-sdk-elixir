defmodule Core.Account do
  @moduledoc """
   High-level module for Account-related activities.
  """
  alias Core.Client
  alias Utils.Transaction
  alias Utils.Account, as: AccountUtil
  alias AeternityNode.Model.{SpendTx, InlineResponse2001, GenericSignedTx}
  alias AeternityNode.Api.Chain

  @default_payload ""
  @prefix_byte_size 2
  @allowed_recipient_tags ["ak", "ct", "ok", "nm"]

  @doc """
  Send tokens to an account.

  ## Examples:

   Client example can be found at: `Core.Client.new/4`
   iex> Core.Account.spend(client, pubkey, 10_000_000, 1_000_000_000_000)
      {:ok,
       %AeternityNode.Model.GenericSignedTx{
       block_hash: "mh_25j4Pu2V2R6LaQajH61AgdgwK7kAqpZPBnSZaH5nDDv8oWX8W6",
       block_height: 68271,
       hash: "th_rEeBN6FJhq6Rzc8F5TLySn8QCykPf3cNBA4P1xhb2kF2F2N9L",
       signatures: ["sg_SPAt7ttaGC372GhxoU1raZWRLjrWNMQsjBVrFBBdjcGPP6hzPotFM4q9PJQCKwSwPBkTKdH33NkkvS5T38G3uS1UZXNN1"],
       tx: %AeternityNode.Model.GenericTx{type: "SpendTx", version: 1}
      }}


  """
  @spec spend(Client.t(), binary(), non_neg_integer(), list()) ::
          {:ok, AeternityNode.Model.GenericSignedTx.t()}
          | {:error, String.t()}
          | {:error, Env.t()}
  def spend(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>>,
            secret: privkey
          },
          network_id: network_id,
          connection: connection
        } = client,
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
        amount,
        gas_price,
        opts \\ []
      )
      when recipient_prefix in @allowed_recipient_tags and
             sender_prefix == "ak" and gas_price > 0 do
    with {:ok, spend_tx} <-
           build_spend_tx_fields(
             client,
             recipient_id,
             amount,
             gas_price,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :payload, @default_payload)
           ),
         {:ok, %GenericSignedTx{} = tx} <-
           Transaction.post(connection, privkey, network_id, spend_tx) do
      {:ok, Map.from_struct(tx)}
    else
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of SpendTX"}
    end
  end

  defp build_spend_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           network_id: network_id,
           connection: connection
         },
         recipient_pubkey,
         amount,
         gas_price,
         fee,
         ttl,
         payload
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, spend_tx} <-
           create_spend_tx(
             recipient_pubkey,
             amount,
             fee,
             ttl,
             sender_pubkey,
             nonce,
             payload
           ),
         {:ok, %InlineResponse2001{height: height}} <-
           Chain.get_current_key_block_height(connection) do
      fee =
        case gas_price do
          :minimum_protocol_gas_price ->
            Transaction.calculate_min_fee(spend_tx, height, network_id)

          gas_price when gas_price > 0 ->
            Transaction.min_gas(spend_tx, height) * gas_price
        end

      {:ok,
       struct(SpendTx,
         sender_id: sender_pubkey,
         recipient_id: recipient_pubkey,
         amount: amount,
         fee: fee,
         ttl: ttl,
         nonce: nonce,
         payload: payload
       )}
    else
      {:error, _info} = error -> error
    end
  end

  defp create_spend_tx(
         recipient_id,
         amount,
         fee,
         ttl,
         sender_id,
         nonce,
         payload
       ) do
    {:ok,
     %SpendTx{
       recipient_id: recipient_id,
       amount: amount,
       fee: fee,
       ttl: ttl,
       sender_id: sender_id,
       nonce: nonce,
       payload: payload
     }}
  end
end
