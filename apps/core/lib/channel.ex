defmodule Core.Channel do
  alias AeternityNode.Api.Channel, as: ChannelAPI
  alias Core.Client

  alias AeternityNode.Model.Error

  @spec get_by_pubkey(Core.Client.t(), binary()) ::
          {:error, Tesla.Env.t()} | {:ok, AeternityNode.Model.Channel.t()}
  def get_by_pubkey(%Client{connection: connection}, channel_pubkey) do
    prepare_result(ChannelAPI.get_channel_by_pubkey(connection, channel_pubkey))
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
