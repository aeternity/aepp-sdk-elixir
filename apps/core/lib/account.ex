defmodule Core.Account do
  @moduledoc """
   High-level module for Account-related activities.
  """
  alias Core.Client
  alias Utils.Transaction
  alias AeternityNode.Model.{SpendTx, InlineResponse2001}
  alias AeternityNode.Model.{Account, Error}
  alias Tesla.Env
  alias AeternityNode.Api.Account, as: AccountApi
  alias AeternityNode.Api.Chain

  @prefix_byte_size 2
  @allowed_recipient_tags ["ak", "ct", "ok", "nm"]

  @doc """
  Builds and posts a new spend transaction.

  ## Examples:

   iex> pubkey = "ak_2GSHayUGeqHXz2unJKpioHkXFXzjWBf3GhzVjQPdJunpBb4HT4"
   iex> privkey = "42225194122641a843a160c92bf4b466213207299e4b6cbd3388ad31445b0d83a6beceb8f376deca8122846ad08f16212220eb9372ef6e6c28a7c93986a6ad3b"
   iex> network_id = "ae_uat"
   iex> url = "https://sdk-testnet.aepps.com/v2"
   iex> internal_url = "https://sdk-testnet.aepps.com/v2"
   iex> client = Core.Client.new(%{pubkey: pubkey, privkey: privkey}, network_id, url, internal_url)
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
      when recipient_prefix in @allowed_recipient_tags and
             sender_prefix == "ak" do
    with {:ok, spend_tx_fields} <-
           build_spend_tx_fields(
             client,
             recipient_id,
             amount,
             Keyword.get(opts, :fee, 0),
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :payload, ""),
             Keyword.get(opts, :gas_price, :minimum_protocol_gas_price)
           ) do
      Transaction.post(connection, privkey, network_id, struct(SpendTx, spend_tx_fields))
    else
      _ -> {:error, "#{__MODULE__}: Unsuccessful post of SpendTX"}
    end
  end

  @doc """
  Get the next valid nonce for a public key

  ## Examples
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> Account.next_valid_nonce(connection, public_key)
      {:ok, 8544}
  """
  @spec next_valid_nonce(Tesla.Client.t(), String.t()) ::
          {:ok, integer()} | {:error, String.t()} | {:error, Env.t()}
  def next_valid_nonce(connection, public_key) do
    response = AccountApi.get_account_by_pubkey(connection, public_key)

    prepare_result(response)
  end

  @doc """
  Get the nonce after a block indicated by hash

  ## Examples
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> block_hash = "kh_WPQzXtyDiwvUs54N1L88YsLPn51PERHF76bqcMhpT5vnrAEAT"
      iex> Account.nonce_at_hash(connection, public_key, block_hash)
      {:ok, 8327}
  """
  @spec nonce_at_hash(Tesla.Client.t(), String.t(), String.t()) ::
          {:ok, integer()} | {:error, String.t()} | {:error, Env.t()}
  def nonce_at_hash(connection, public_key, block_hash) do
    response = AccountApi.get_account_by_pubkey_and_hash(connection, public_key, block_hash)

    prepare_result(response)
  end

  defp prepare_result(response) do
    case response do
      {:ok, %Account{nonce: nonce}} ->
        {:ok, nonce + 1}

      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}
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
         fee,
         ttl,
         payload,
         gas_price
       ) do
    with {:ok, nonce} <- next_valid_nonce(connection, sender_pubkey),
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
       [
         sender_id: sender_pubkey,
         recipient_id: recipient_pubkey,
         amount: amount,
         fee: fee,
         ttl: ttl,
         nonce: nonce,
         payload: payload
       ]}
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
