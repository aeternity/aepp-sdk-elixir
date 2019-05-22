defmodule Core.Account do
  @moduledoc """
   High-level module for Account-related activities.
  """
  alias Core.Client
  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Model.{Account, SpendTx, Error}
  alias Utils.{Transaction, Encoding}
  alias Utils.Account, as: AccountUtil
  alias Tesla.Env

  @prefix_byte_size 2
  @allowed_recipient_tags ["ak", "ct", "ok", "nm"]

  @type account :: %{id: String.t(), balance: non_neg_integer(), nonce: non_neg_integer()}

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
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_id,
            secret: privkey
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
        amount,
        opts \\ []
      )
      when recipient_prefix in @allowed_recipient_tags and sender_prefix == "ak" do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_id),
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection),
         %SpendTx{fee: fee} = spend_tx <-
           struct(SpendTx,
             sender_id: sender_id,
             recipient_id: recipient_id,
             amount: amount,
             fee: Keyword.get(opts, :fee, Transaction.dummy_fee()),
             ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
             nonce: nonce,
             payload: Keyword.get(opts, :payload, Transaction.default_payload())
           ),
         fee when is_integer(fee) <-
           Transaction.calculate_fee(spend_tx, height, network_id, fee, gas_price),
         {:ok, response} <-
           Transaction.post(connection, privkey, network_id, %{spend_tx | fee: fee}) do
      {:ok, response}
    else
      err -> prepare_result(err)
    end
  end

  @spec balance(Client.t(), String.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  def balance(%Client{connection: connection}, pubkey) when is_binary(pubkey) do
    case AccountApi.get_account_by_pubkey(connection, pubkey) do
      {:ok, %Account{balance: balance}} ->
        {:ok, balance}

      _ = response ->
        prepare_result(response)
    end
  end

  @spec balance(Client.t(), String.t(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  def balance(%Client{} = client, pubkey, height) when is_binary(pubkey) and is_integer(height) do
    response = get(client, pubkey, height)

    prepare_result(response)
  end

  @spec balance(Client.t(), String.t(), String.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  def balance(%Client{} = client, pubkey, block_hash)
      when is_binary(pubkey) and is_binary(block_hash) do
    response = get(client, pubkey, block_hash)

    prepare_result(response)
  end

  @spec get(Client.t(), String.t(), non_neg_integer()) ::
          {:ok, account()} | {:error, String.t()} | {:error, Env.t()}
  def get(%Client{connection: connection}, pubkey, height)
      when is_binary(pubkey) and is_integer(height) do
    response = AccountApi.get_account_by_pubkey_and_height(connection, pubkey, height)

    prepare_result(response)
  end

  @spec get(Client.t(), String.t(), String.t()) ::
          {:ok, account()} | {:error, String.t()} | {:error, Env.t()}
  def get(%Client{connection: connection}, pubkey, block_hash)
      when is_binary(pubkey) and is_binary(block_hash) do
    response = AccountApi.get_account_by_pubkey_and_hash(connection, pubkey, block_hash)

    prepare_result(response)
  end

  defp prepare_result({:ok, %Account{} = account}) do
    account_map = Map.from_struct(account)

    {:ok, account_map}
  end

  defp prepare_result({:ok, %{balance: balance}}) do
    {:ok, balance}
  end

  defp prepare_result({:ok, %Error{reason: message}}) do
    {:error, message}
  end

  defp prepare_result({:error, %Env{}} = error) do
    error
  end
end
