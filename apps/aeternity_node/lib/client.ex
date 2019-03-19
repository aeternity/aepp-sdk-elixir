defmodule AeternityNode.Client do
  use Tesla

  alias __MODULE__

  defstruct [:keypair, :network_id, :connection, :internal_connection]

  @type t :: %Client{
          keypair: keypair(),
          network_id: String.t(),
          connection: Tesla.Env.client(),
          internal_connection: Tesla.Env.client()
        }

  @type keypair :: %{pubkey: String.t(), privkey: String.t()}

  plug(Tesla.Middleware.Headers, [{"User-Agent", "Elixir"}])
  plug(Tesla.Middleware.EncodeJson)

  @doc """
  Client constructor
  """
  @spec new(keypair(), String.t(), String.t(), String.t()) :: Client.t()
  def new(%{pubkey: _, privkey: _} = keypair, network_id, url, internal_url) do
    connection = Tesla.client([{Tesla.Middleware.BaseUrl, url}])
    internal_connection = Tesla.client([{Tesla.Middleware.BaseUrl, internal_url}])

    %Client{
      keypair: keypair,
      network_id: network_id,
      connection: connection,
      internal_connection: internal_connection
    }
  end
end
