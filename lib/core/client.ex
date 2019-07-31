defmodule Core.Client do
  @moduledoc """
  Contains the Client structure, holding all the data that is needed in order to use the SDK.
  """
  use Tesla

  alias __MODULE__
  alias AeternityNode.Connection

  @default_gas_price 1_000_000

  defstruct [
    :keypair,
    :network_id,
    :connection,
    :internal_connection,
    gas_price: @default_gas_price
  ]

  @type t :: %Client{
          keypair: keypair(),
          network_id: String.t(),
          connection: struct(),
          internal_connection: struct(),
          gas_price: non_neg_integer()
        }

  @type keypair :: %{public: String.t(), secret: String.t()}

  plug(Tesla.Middleware.Headers, [{"User-Agent", "Elixir"}])
  plug(Tesla.Middleware.EncodeJson)
  adapter(Tesla.Adapter.Hackney, recv_timeout: 30_000)

  @doc """
  Client constructor

  ## Example
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> secret_key = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> url = "https://sdk-testnet.aepps.com/v2"
      iex> internal_url = "https://sdk-testnet.aepps.com/v2"
      iex> Core.Client.new(%{public: public_key, secret: secret_key}, network_id, url, internal_url)
      %Core.Client{
        connection: %Tesla.Client{
          adapter: nil,
          fun: nil,
          post: [],
          pre: [
            {Tesla.Middleware.BaseUrl, :call, ["https://sdk-testnet.aepps.com/v2"]}
          ]
        },
        gas_price: 0,
        internal_connection: %Tesla.Client{
          adapter: nil,
          fun: nil,
          post: [],
          pre: [
            {Tesla.Middleware.BaseUrl, :call, ["https://sdk-testnet.aepps.com/v2"]}
          ]
        },
        keypair: %{
          secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61",
          public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
        },
        network_id: "ae_uat"
      }
  """
  @spec new(keypair(), String.t(), String.t(), String.t(), non_neg_integer()) :: Client.t()
  def new(
        %{public: public_key, secret: secret_key} = keypair,
        network_id,
        url,
        internal_url,
        gas_price \\ @default_gas_price
      )
      when is_binary(public_key) and is_binary(secret_key) and is_binary(network_id) and
             is_binary(url) and is_binary(internal_url) do
    connection = Connection.new(url)
    internal_connection = Connection.new(internal_url)

    %Client{
      keypair: keypair,
      network_id: network_id,
      connection: connection,
      internal_connection: internal_connection,
      gas_price: gas_price
    }
  end
end
