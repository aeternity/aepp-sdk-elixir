defmodule AeppSDKElixir.Account.Account do
  @type error :: {:error, String.t()}

  @spec get_balance(String.t()) :: integer() | error()
  def get_balance(key) when is_binary(key) do
    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.get("http://127.0.0.1:3013/v2/accounts/#{key}")

    Poison.decode!(body)["balance"]
  end

  def get_balance(key) do
    {:error, "#{__MODULE__}: The key: #{key} is not a string"}
  end
end
