defmodule Core.Client do
  use Tesla

  alias __MODULE__
  alias AeternityNode.Connection

  defstruct [:keypair, :network_id, :connection, :internal_connection]

  @type t :: %Client{
          keypair: keypair(),
          network_id: String.t(),
          connection: struct(),
          internal_connection: struct()
        }

  @type keypair :: %{pubkey: String.t(), privkey: String.t()}

  plug(Tesla.Middleware.Headers, [{"User-Agent", "Elixir"}])
  plug(Tesla.Middleware.EncodeJson)

  @doc """
  Client constructor

  ## Examples
      iex> pubkey = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> privkey = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> url = "https://sdk-testnet.aepps.com/v2"
      iex> internal_url = "https://sdk-testnet.aepps.com/v2"
      iex> Core.Client.new(%{pubkey: pubkey, privkey: privkey}, network_id, url, internal_url)
      %Core.Client{
        connection: %Tesla.Client{
          adapter: nil,
          fun: nil,
          post: [],
          pre: [
            {Tesla.Middleware.BaseUrl, :call, ["https://sdk-testnet.aepps.com/v2"]}
          ]
        },
        internal_connection: %Tesla.Client{
          adapter: nil,
          fun: nil,
          post: [],
          pre: [
            {Tesla.Middleware.BaseUrl, :call, ["https://sdk-testnet.aepps.com/v2"]}
          ]
        },
        keypair: %{
          privkey: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61",
          pubkey: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
        },
        network_id: "ae_uat"
      }
  """
  @spec new(keypair(), String.t(), String.t(), String.t()) :: Client.t()
  def new(%{pubkey: pubkey, privkey: privkey} = keypair, network_id, url, internal_url)
      when is_binary(pubkey) and is_binary(privkey) and is_binary(network_id) and is_binary(url) and
             is_binary(internal_url) do
    connection = Connection.new(url)
    internal_connection = Connection.new(internal_url)

    %Client{
      keypair: keypair,
      network_id: network_id,
      connection: connection,
      internal_connection: internal_connection
    }
  end
end
