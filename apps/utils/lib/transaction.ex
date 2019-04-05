defmodule Utils.Transaction do
  @moduledoc """
  false
  """
  alias AeternityNode.Api.Transaction, as: TransactionApi
  alias AeternityNode.Model.{PostTxResponse, ContractCallObject, Tx, Error}
  alias Utils.{Keys, Encoding, Serialization}
  alias Tesla.Env

  @await_attempts 25
  @await_attempt_interval 200
  @default_ttl 0

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
