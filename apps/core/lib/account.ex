defmodule Core.Account do
  @moduledoc """
   High-level module for Account-related activities.
  """
  alias Core.Client
  alias Utils.{Transaction, Encoding}
  alias Utils.Account, as: AccountUtil
  alias AeternityNode.Model.SpendTx

  @default_payload ""
  @prefix_byte_size 2
  @allowed_recipient_tags ["ak", "ct", "ok", "nm"]

  @doc """
  Send tokens to an account.

  ## Examples:

   Client example can be found at: `Core.Client.new/4`
   iex> Core.Account.spend(client, public_key, 10_000_000, fee: 1_000_000_000_000_000)
      {:ok,
        %{
          block_hash: "mh_2hM7ZkifnstA9HEdpZRwKjZgNUSrkVmrB1jmCgG7Ly2b1vF7t",
          block_height: 74871,
          tx_hash: "th_FBqci65KYGsup7GettzvWVxP91podgngX9EJK2BDiduFf8FY4"
        }}
  """
  @spec spend(Client.t(), binary(), non_neg_integer(), list()) ::
          {:ok,
           %{
             block_hash: Encoding.base58c(),
             block_height: non_neg_integer(),
             tx_hash: Encoding.base58c()
           }}
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
        opts \\ []
      )
      when recipient_prefix in @allowed_recipient_tags and sender_prefix == "ak" do
    with {:ok, spend_tx} <-
           build_spend_tx_fields(
             client,
             recipient_id,
             amount,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, Transaction.default_ttl()),
             Keyword.get(opts, :payload, @default_payload)
           ),
         {:ok, response} <- Transaction.post(connection, privkey, network_id, spend_tx) do
      {:ok, response}
    else
      {:error, _} = err -> err
    end
  end

  defp build_spend_tx_fields(
         %Client{
           keypair: %{
             public: sender_pubkey
           },
           connection: connection
         },
         recipient_pubkey,
         amount,
         fee,
         ttl,
         payload
       ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey) do
      {:ok,
       struct(
         SpendTx,
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
end
