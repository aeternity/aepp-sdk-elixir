defmodule Aeternal.Connection do
  @moduledoc """
  Handle Tesla connections for Aeternal.
  """

  use Tesla

  plug(Tesla.Middleware.Headers, [{"user-agent", "Elixir"}])
  plug(Tesla.Middleware.EncodeJson, engine: Poison)

  @doc """
  Configure an authless client connection

  # Returns

  Tesla.Env.client
  """
  @spec new() :: Tesla.Env.client()
  def new do
    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}
    Tesla.client([{Tesla.Middleware.BaseUrl, "http://localhost:3013/v2"}], adapter)
  end

  @spec new(String.t()) :: Tesla.Env.client()
  def new(path) do
    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}
    Tesla.client([{Tesla.Middleware.BaseUrl, path}], adapter)
  end
end
