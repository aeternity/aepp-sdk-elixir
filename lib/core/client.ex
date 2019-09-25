defmodule AeppSDK.Client do
  @moduledoc """
  Contains the Client structure, holding all the data that is needed in order to use the SDK.
  """

  alias __MODULE__

  @default_gas_price 1_000_000

  defstruct [
    :keypair,
    :network_id,
    :node_name,
    :node_cookie,
    gas_price: @default_gas_price
  ]

  @type t :: %Client{
          keypair: keypair(),
          network_id: String.t(),
          node_name: atom(),
          node_cookie: atom(),
          gas_price: non_neg_integer()
        }

  @type keypair :: %{public: String.t(), secret: String.t()}

  @doc """
  Client constructor

  ## Example
      iex> public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
      iex> secret_key = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
      iex> network_id = "ae_uat"
      iex> node_name = :aeternity@localhost
      iex> node_cookie = :aeternity_cookie
      iex> AeppSDK.Client.new(%{public: public_key, secret: secret_key}, network_id, node_name, node_cookie)
      %AeppSDK.Client{
          gas_price: 1000000,
          keypair: %{
            public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
            secret: "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
          },
          network_id: "ae_uat",
          node_cookie: :aeternity_cookie,
          node_name: :aeternity@localhost
        }
  """
  @spec new(keypair(), String.t(), atom(), atom(), non_neg_integer()) :: Client.t()
  def new(
        %{public: public_key, secret: secret_key} = keypair,
        network_id,
        node_name,
        node_cookie,
        gas_price \\ @default_gas_price
      )
      when is_binary(public_key) and is_binary(secret_key) and is_binary(network_id) and
             is_atom(node_name) and is_atom(node_cookie) do
    %Client{
      keypair: keypair,
      network_id: network_id,
      node_name: node_name,
      node_cookie: node_cookie,
      gas_price: gas_price
    }
  end
end
