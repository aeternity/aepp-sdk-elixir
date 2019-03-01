defmodule AeppSDKElixir.Account.Account do
  alias AeppSDKElixir.Client.Worker, as: Client

  @type error :: {:error, String.t()}

  @spec get_balance(String.t()) :: {:ok, integer()} | error()
  def get_balance(key) when is_binary(key) do
    case Client.get_url() do
      {:ok, url} ->
        path = "#{url}/v2/accounts/#{key}"

        case Client.http_get(path) do
          {:ok, %{"balance" => balance}} ->
            {:ok, balance}

          {:error, _} = err ->
            err
        end

      {:error, _} = err ->
        err
    end
  end

  def get_balance(_) do
    {:error, "#{__MODULE__}: Invalid pubkey type"}
  end
end
