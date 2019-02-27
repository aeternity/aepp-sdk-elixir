defmodule AeppSDKElixir.Account.Account do

  alias AeppSDKElixir.Client.Worker, as: Client

  @type error :: {:error, String.t()}

  @spec get_balance(String.t()) :: integer() | error()
  def get_balance(key) when is_binary(key) do
    url = Client.get_url()
    path = "#{url}/v2/accounts/#{key}"

    case Client.http_get(path) do
      {:ok, %{"balance" => balance}} ->
        {:ok, balance}
      {:error, _} = error ->
        error
    end
  end

  def get_balance(key) do
    {:error, "#{__MODULE__}: The key: #{key} is not a string"}
  end
end
