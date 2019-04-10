defmodule Utils.Transaction do
  @moduledoc """
  Transaction utils
  """
  alias AeternityNode.Api.Transaction, as: TransactionApi
  alias AeternityNode.Model.{PostTxResponse, ContractCallObject, Tx, Error}
  alias Utils.{Keys, Encoding, Serialization}
  alias Tesla.Env

  @await_attempts 25
  @await_attempt_interval 200
  @default_ttl 0

  @doc """
  Serialize the list of fields to an RLP transaction binary, sign it with the private key and network ID and post it to the node

  ## Examples
      iex> connection = AeternityNode.Connection.new("https://sdk-testnet.aepps.com/v2")
      iex> network_id = "ae_uat"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> fields = [{:id, :account,
      <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
        91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>},
      8644,
      {:id, :contract,
      <<75, 88, 127, 65, 200, 133, 162, 250, 205, 37, 201, 60, 125, 15, 3, 212,
        140, 118, 229, 188, 161, 31, 255, 150, 107, 222, 254, 189, 209, 7, 65,
        47>>},
      1,
      2000000000000000000,
      0,
      0,
      1000000,
      1000000000,
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 32, 112, 194, 27, 63, 171, 248, 210, 119, 144, 238, 34,
       30, 100, 222, 2, 111, 12, 11, 11, 82, 86, 82, 53, 206, 145, 155, 60, 13,
       206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33>>]
      iex> type = :contract_call_tx
      iex> Utils.Transaction.post(connection, privkey, network_id, fields, type)
      {:ok,
      %AeternityNode.Model.ContractCallObject{
        caller_id: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
        caller_nonce: 8644,
        contract_id: "ct_aBc4nGeD92k6cV9kLBUBvKhco9Vnsv1LhRhsFe6tmp7zyq7Zq",
        gas_price: 1000000000,
        gas_used: 252,
        height: 62918,
        log: [],
        return_type: "ok",
        return_value: "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA"
      }}
  """
  @spec post(struct(), String.t(), String.t(), list(), atom()) ::
          {:ok, ContractCallObject.t()} | {:error, String.t()} | {:error, Env.t()}
  def post(connection, privkey, network_id, fields, type) do
    serialized_fields = Serialization.serialize(fields, type)

    signature =
      Keys.sign(
        serialized_fields,
        Keys.privkey_to_binary(privkey),
        network_id
      )

    signed_tx_fields = [[signature], serialized_fields]
    serialized_signed_tx = Serialization.serialize(signed_tx_fields, :signed_tx)
    encoded_signed_tx = Encoding.prefix_encode_base64("tx", serialized_signed_tx)

    with {:ok, %PostTxResponse{tx_hash: tx_hash}} <-
           TransactionApi.post_transaction(connection, %Tx{
             tx: encoded_signed_tx
           }),
         {:ok, %ContractCallObject{}} = response <- await_mining(connection, tx_hash) do
      response
    else
      {:ok, %Error{reason: message}} ->
        {:error, message}

      {:error, %Env{} = env} ->
        {:error, env}

      {:error, _} = error ->
        error
    end
  end

  defp await_mining(connection, tx_hash) do
    await_mining(connection, tx_hash, @await_attempts)
  end

  defp await_mining(_connection, _tx_hash, 0),
    do:
      {:error,
       "Transaction wasn't mined after #{@await_attempts * @await_attempt_interval / 1000} seconds"}

  defp await_mining(connection, tx_hash, attempts) do
    :timer.sleep(@await_attempt_interval)

    case TransactionApi.get_transaction_info_by_hash(connection, tx_hash) do
      {:ok, %ContractCallObject{}} = response ->
        response

      {:ok, %Error{}} ->
        await_mining(connection, tx_hash, attempts - 1)

      {:error, %Env{} = env} ->
        {:error, env}
    end
  end

  # TODO: to be calculated dynamically
  def calculate_min_fee(), do: 2_000_000_000_000_000_000

  def default_ttl, do: @default_ttl
end
