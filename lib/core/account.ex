defmodule AeppSDK.Account do
  @moduledoc """
   High-level module for Account-related activities.

   In order for its functions to be used, a client must be defined first.
   Client example can be found at: `AeppSDK.Client.new/4`
  """
  alias AeppSDK.Client
  alias AeppSDK.Utils.{Keys, SerializationUtils}
  #   alias AeppSDK.Utils.Account, as: AccountUtils
  #   alias AeppSDK.Utils.{Encoding, Transaction}

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
      iex> AeppSDK.Account.spend(client, public_key, 10_000_000, fee: 1_000_000_000_000_000)
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
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender,
            secret: secret
          },
          network_id: network_id,
          node_name: node_name
        } = client,
        <<recipient_prefix::binary-size(@prefix_byte_size), _::binary>> = recipient,
        amount,
        opts \\ []
      )
      when recipient_prefix in @allowed_recipient_tags and sender_prefix == "ak" do
    sender_id = {_, _, pub_key} = SerializationUtils.proccess_id_to_record(sender)
    recipient_id = SerializationUtils.proccess_id_to_record(recipient)
    height = get_height(client)
    next_nonce = next_nonce(client)

    spend_tx = %{
      sender_id: sender_id,
      recipient_id: recipient_id,
      amount: amount,
      fee: Keyword.get(opts, :fee, 0),
      nonce: next_nonce,
      payload: Keyword.get(opts, :payload, <<>>)
    }

    {:ok, aetx} = :rpc.call(node_name, :aec_spend_tx, :new, [spend_tx])
    fee = :rpc.call(node_name, :aetx, :min_fee, [aetx, height])
    {_, _, _, _, spend_tx} = aetx

    new_spend_tx =
      spend_tx
      |> Tuple.delete_at(4)
      |> Tuple.insert_at(4, fee)

    new_aetx =
      aetx
      |> Tuple.delete_at(4)
      |> Tuple.insert_at(4, new_spend_tx)

    serialized_aetx = :rpc.call(node_name, :aetx, :serialize_to_binary, [new_aetx])
    secret_key_to_binary = Keys.secret_key_to_binary(secret)
    signatures = Keys.sign(serialized_aetx, secret_key_to_binary, network_id)
    signed_tx = :rpc.call(node_name, :aetx_sign, :new, [new_aetx, [signatures]])
    :rpc.call(node_name, :aec_tx_pool, :push, [signed_tx])
  end

  def next_nonce(%{keypair: %{public: public_key}, node_name: node_name}) do
    public_key_binary = Keys.public_key_to_binary(public_key)

    {_, {_, _, _, nonce, _, _, _}} =
      :rpc.call(node_name, :aec_chain, :get_account, [public_key_binary])

    nonce + 1
  end

  def next_nonce(client, public_key) do
    public_key_binary = Keys.public_key_to_binary(public_key)

    {_, {_, _, _, nonce, _, _, _}} =
      :rpc.call(client.node_name, :aec_chain, :get_account, [public_key_binary])

    nonce + 1
  end

  def get_height(%{node_name: node_name}) do
    {_, {_, height, _, _, _, _, _, _, _, _, _, _, _}} =
      :rpc.call(node_name, :aec_chain, :top_block, [])

    height
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
  def balance(%Client{node_name: node_name, keypair: %{public: public_key}})
      when is_binary(public_key) do
    public_key_binary = Keys.public_key_to_binary(public_key)

    {_, {_, _, balance, _, _, _, _}} =
      :rpc.call(node_name, :aec_chain, :get_account, [public_key_binary])

    balance
  end

  def balance(%Client{node_name: node_name}, public_key) when is_binary(public_key) do
    public_key_binary = Keys.public_key_to_binary(public_key)

    {_, {_, _, balance, _, _, _, _}} =
      :rpc.call(node_name, :aec_chain, :get_account, [public_key_binary])

    balance
  end

  #   @doc """
  #   Get an account's balance at a given height

  #   ## Example
  #       iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
  #       iex> height = 80000
  #       iex> AeppSDK.Account.balance(client, pubkey, height)
  #       {:ok, 1641606227460612819475}
  #   """
  #   @spec balance(Client.t(), String.t(), non_neg_integer()) ::
  #           {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  #   def balance(%Client{} = client, pubkey, height) when is_binary(pubkey) and is_integer(height) do
  #     response = get(client, pubkey, height)

  #     prepare_result(response)
  #   end

  #   @doc """
  #   Get an account's balance at a given block hash

  #   ## Example
  #       iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
  #       iex> block_hash = "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P"
  #       iex> AeppSDK.Account.balance(client, pubkey, block_hash)
  #       {:ok, 1653014562214254044805}
  #   """
  #   @spec balance(Client.t(), String.t(), String.t()) ::
  #           {:ok, non_neg_integer()} | {:error, String.t()} | {:error, Env.t()}
  #   def balance(%Client{} = client, pubkey, block_hash)
  #       when is_binary(pubkey) and is_binary(block_hash) do
  #     response = get(client, pubkey, block_hash)

  #     prepare_result(response)
  #   end

  #   @doc """
  #   Get an account at a given height

  #   ## Example
  #       iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
  #       iex> height = 80000
  #       iex> AeppSDK.Account.get(client, pubkey, height)
  #       {:ok,
  #        %{
  #          auth_fun: nil,
  #          balance: 1641606227460612819475,
  #          contract_id: nil,
  #          id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
  #          kind: "basic",
  #          nonce: 11215
  #        }}
  #   """
  #   @spec get(Client.t(), String.t(), non_neg_integer()) ::
  #           {:ok, account()} | {:error, String.t()} | {:error, Env.t()}
  #   def get(%Client{connection: connection}, pubkey, height)
  #       when is_binary(pubkey) and is_integer(height) do
  #     response = AccountApi.get_account_by_pubkey_and_height(connection, pubkey, height)

  #     prepare_result(response)
  #   end

  #   @doc """
  #   Get an account at a given block hash

  #   ## Example
  #       iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
  #       iex> block_hash = "kh_2XteYFUyUYjnMDJzHszhHegpoV59QpWTLnMPw5eohsXntzdf6P"
  #       iex> AeppSDK.Account.get(client, pubkey, block_hash)
  #       {:ok,
  #        %{
  #          auth_fun: nil,
  #          balance: 1653014562214254044805,
  #          contract_id: nil,
  #          id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
  #          kind: "basic",
  #          nonce: 11837
  #        }}
  #   """
  #   @spec get(Client.t(), String.t(), String.t()) ::
  #           {:ok, account()} | {:error, String.t()} | {:error, Env.t()}
  #   def get(%Client{connection: connection}, pubkey, block_hash)
  #       when is_binary(pubkey) and is_binary(block_hash) do
  #     response = AccountApi.get_account_by_pubkey_and_hash(connection, pubkey, block_hash)

  #     prepare_result(response)
  #   end

  #   defp prepare_result({:ok, %Account{} = account}) do
  #     account_map = Map.from_struct(account)

  #     {:ok, account_map}
  #   end

  #   defp prepare_result({:ok, %{balance: balance}}) do
  #     {:ok, balance}
  #   end

  #   defp prepare_result({:ok, %Error{reason: message}}) do
  #     {:error, message}
  #   end

  #   defp prepare_result({:error, _} = error) do
  #     error
  #   end
end
