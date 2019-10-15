defmodule AeppSDK.Account do
  @moduledoc """
   High-level module for Account-related activities.

   In order for its functions to be used, a client must be defined first.
   Client example can be found at: `AeppSDK.Client.new/4`
  """
  alias AeppSDK.Client
  alias AeppSDK.Utils.Account, as: AccountUtils
  alias AeppSDK.Utils.{Encoding, Transaction}

  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Api.Chain, as: ChainApi
  alias AeternityNode.Model.{Account, Error, SpendTx}

  alias Tesla.Env

  @prefix_byte_size 2
  @allowed_recipient_tags ["ak", "ct", "ok", "nm"]

  @type account :: %{id: String.t(), balance: non_neg_integer(), nonce: non_neg_integer()}
  @type spend_options :: [
          fee: non_neg_integer(),
          ttl: non_neg_integer(),
          payload: String.t()
        ]

  @doc """
  Send tokens to an account.

  ## Example
      iex> public_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
      iex> AeppSDK.Account.spend(client, public_key, 10_000_000)
      {:ok,
        %{
        block_hash: "mh_2hM7ZkifnstA9HEdpZRwKjZgNUSrkVmrB1jmCgG7Ly2b1vF7t",
        block_height: 74871,
        tx_hash: "th_FBqci65KYGsup7GettzvWVxP91podgngX9EJK2BDiduFf8FY4"
      }}
  """
  @spec spend(Client.t(), binary(), non_neg_integer(), spend_options()) ::
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
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_id
          },
          connection: connection,
          network_id: network_id,
          gas_price: gas_price
        } = client,
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient_id,
        amount,
        opts \\ []
      )
      when recipient_prefix in @allowed_recipient_tags and sender_prefix == "ak" do
    user_fee = Keyword.get(opts, :fee, Transaction.dummy_fee())

    with {:ok, nonce} <- AccountUtils.next_valid_nonce(connection, sender_id),
         {:ok, %{height: height}} <- ChainApi.get_current_key_block_height(connection),
         %SpendTx{} = spend_tx <-
           struct(
             SpendTx,
             sender_id: sender_id,
             recipient_id: recipient_id,
             amount: amount,
             fee: user_fee,
             ttl: Keyword.get(opts, :ttl, Transaction.default_ttl()),
             nonce: nonce,
             payload: Keyword.get(opts, :payload, Transaction.default_payload())
           ),
         new_fee <-
           Transaction.calculate_n_times_fee(
             spend_tx,
             height,
             network_id,
             user_fee,
             gas_price,
             Transaction.default_fee_calculation_times()
           ),
         {:ok, _response} = response <-
           Transaction.post(
             client,
             %{spend_tx | fee: new_fee},
             Keyword.get(opts, :auth, :no_auth),
             :no_channels
           ) do
      response
    else
      err -> prepare_result(err)
    end
  end

  @doc """
  Get an account's balance

  ## Example
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> AeppSDK.Account.balance(client, pubkey)
      {:ok, 1652992279192254044805}
  """
  @spec balance(Client.t(), String.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  def balance(%Client{} = client, pubkey) when is_binary(pubkey) do
    case get(client, pubkey) do
      {:ok, %{balance: balance}} ->
        {:ok, balance}

      _ = response ->
        prepare_result(response)
    end
  end

  @doc """
  Get an account's balance at a given height

  ## Example
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> height = 80000
      iex> AeppSDK.Account.balance(client, pubkey, height)
      {:ok, 1641606227460612819475}
  """
  @spec balance(Client.t(), String.t(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  def balance(%Client{} = client, pubkey, height) when is_binary(pubkey) and is_integer(height) do
    response = get(client, pubkey, height)

    prepare_result(response)
  end

  @doc """
  Get an account's balance at a given block hash

  ## Example
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> block_hash = "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P"
      iex> AeppSDK.Account.balance(client, pubkey, block_hash)
      {:ok, 1653014562214254044805}
  """
  @spec balance(Client.t(), String.t(), String.t()) ::
          {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  def balance(%Client{} = client, pubkey, block_hash)
      when is_binary(pubkey) and is_binary(block_hash) do
    response = get(client, pubkey, block_hash)

    prepare_result(response)
  end

  @doc """
  Get an actual account information

  ## Example
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> AeppSDK.Account.get(client, pubkey)
      {:ok,
       %{
         auth_fun: nil,
         balance: 151688000000000000000,
         contract_id: nil,
         id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
         kind: "basic",
         nonce: 0,
         payable: true
       }}
  """
  @spec get(Client.t(), String.t()) ::
          {:ok, account()} | {:error, String.t()} | {:error, Env.t()}
  def get(%Client{connection: connection}, pubkey)
      when is_binary(pubkey) do
    response = AccountApi.get_account_by_pubkey(connection, pubkey)

    prepare_result(response)
  end

  @doc """
  Get an account at a given height

  ## Example
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> height = 80000
      iex> AeppSDK.Account.get(client, pubkey, height)
      {:ok,
       %{
         auth_fun: nil,
         balance: 1641606227460612819475,
         contract_id: nil,
         id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
         kind: "basic",
         nonce: 11215
       }}
  """
  @spec get(Client.t(), String.t(), non_neg_integer()) ::
          {:ok, account()} | {:error, String.t()} | {:error, Env.t()}
  def get(%Client{connection: connection}, pubkey, height)
      when is_binary(pubkey) and is_integer(height) do
    response = AccountApi.get_account_by_pubkey_and_height(connection, pubkey, height)

    prepare_result(response)
  end

  @doc """
  Get an account at a given block hash

  ## Example
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> block_hash = "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P"
      iex> AeppSDK.Account.get(client, pubkey, block_hash)
      {:ok,
       %{
         auth_fun: nil,
         balance: 1653014562214254044805,
         contract_id: nil,
         id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
         kind: "basic",
         nonce: 11837
       }}
  """
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

  defp prepare_result({:error, _} = error) do
    error
  end
end
