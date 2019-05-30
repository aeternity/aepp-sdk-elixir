defmodule Core.Channel do
  alias AeternityNode.Api.Channel, as: ChannelAPI
  alias Core.Client
  alias Utils.Account, as: AccountUtil
  alias AeternityNode.Api.Chain

  alias AeternityNode.Model.Error
  alias AeternityNode.Model.ChannelCreateTx

  @prefix_byte_size 2

  @spec get_by_pubkey(Core.Client.t(), binary()) ::
          {:error, Tesla.Env.t()} | {:ok, AeternityNode.Model.Channel.t()}
  def get_by_pubkey(%Client{connection: connection}, channel_pubkey) do
    prepare_result(ChannelAPI.get_channel_by_pubkey(connection, channel_pubkey))
  end

  def create(
        %Client{
          keypair: %{
            public: <<sender_prefix::binary-size(@prefix_byte_size), _::binary>> = sender_pubkey,
            secret: secret_key
          },
          network_id: network_id,
          connection: connection,
          gas_price: gas_price
        },
        initiator_id,
        initiator_amount,
        responder_id,
        responder_amount,
        push_amount,
        channel_reserve,
        lock_period,
        state_hash,
        opts \\ []
      ) do
    with {:ok, nonce} <- AccountUtil.next_valid_nonce(connection, sender_pubkey),
         {:ok, create_channel_tx} <-
           build_create_channel_tx(
             initiator_id,
             initiator_amount,
             responder_id,
             responder_amount,
             push_amount,
             channel_reserve,
             lock_period,
             Keyword.get(opts, :ttl, 0),
             Keyword.get(opts, :fee, 0),
             nonce,
             state_hash
           ),
         {:ok, %{height: height}} <- Chain.get_current_key_block_height(connection),
         {:ok, _} = response <-
           Transaction.try_post(
             connection,
             secret_key,
             network_id,
             gas_price,
             create_channel_tx,
             height
           ) do
      response
    else
      error -> {:error, "#{__MODULE__}: Unsuccessful post of ChannelCreateTx : #{inspect(error)}"}
    end
  end

  defp build_create_channel_tx(
         initiator_id,
         initiator_amount,
         responder_id,
         responder_amount,
         push_amount,
         channel_reserve,
         lock_period,
         ttl,
         fee,
         nonce,
         state_hash
       ) do
    {:ok,
     %ChannelCreateTx{
       initiator_id: initiator_id,
       initiator_amount: initiator_amount,
       responder_id: responder_id,
       responder_amount: responder_amount,
       push_amount: push_amount,
       channel_reserve: channel_reserve,
       lock_period: lock_period,
       ttl: ttl,
       fee: fee,
       nonce: nonce,
       state_hash: state_hash
     }}
  end

  defp prepare_result({:ok, %Tesla.Env{} = env}) do
    {:error, env}
  end

  defp prepare_result({:ok, response}) do
    {:ok, response}
  end

  defp prepare_result({:error, _} = error) do
    error
  end
end
