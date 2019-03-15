defmodule AeternityNode.Connection do
  @moduledoc """
  Handle Tesla connections for AeternityNode.
  """

  use Tesla

  plug(Tesla.Middleware.Headers, [{"User-Agent", "Elixir"}])
  plug(Tesla.Middleware.EncodeJson)

  @doc """
  Configure an authless client connection

  # Returns

  Tesla.Env.client
  """
  @spec new() :: Tesla.Env.client()
  def new() do
    Tesla.client([{Tesla.Middleware.BaseUrl, "http://localhost:3013/v2"}])
  end

  @spec new(String.t()) :: Tesla.Env.client()
  def new(path) do
    Tesla.client([{Tesla.Middleware.BaseUrl, path}])
  end
end
