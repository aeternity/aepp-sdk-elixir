defmodule AeppSDKElixir.Client.Worker do
  use GenServer

  alias __MODULE__, as: Client

  defstruct [:url, :internal_url, :keypair, :network_id]

  @type t :: %Client{
          url: String.t(),
          internal_url: String.t(),
          keypair: keypair(),
          network_id: String.t()
        }
  @type keypair :: %{pubkey: String.t(), privkey: String.t()}
  @type error :: error()

  def start_link(_args) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %Client{url: nil, internal_url: nil, keypair: nil, network_id: nil}}
  end

  @spec configure(Client.t()) :: :ok | error()
  def configure(
        %Client{
          url: url,
          internal_url: internal_url,
          keypair: %{pubkey: pubkey, privkey: privkey},
          network_id: network_id
        } = client
      )
      when is_binary(url) and is_binary(internal_url) and is_binary(pubkey) and is_binary(privkey) and
             is_binary(network_id),
      do: GenServer.call(__MODULE__, {:configure, client})

  def configure(_), do: {:error, "Invalid client parameters"}

  @spec get_url :: {:ok, String.t()}
  def get_url, do: GenServer.call(__MODULE__, :get_url)

  @spec get_internal_url :: {:ok, String.t()}
  def get_internal_url, do: GenServer.call(__MODULE__, :get_internal_url)

  @spec get_keypair :: {:ok, %{pubkey: String.t(), privkey: String.t()}}
  def get_keypair, do: GenServer.call(__MODULE__, :get_keypair)

  @spec get_network_id :: {:ok, String.t()}
  def get_network_id, do: GenServer.call(__MODULE__, :get_network_id)

  @spec set_url(String.t()) :: :ok | error()
  def set_url(url) when is_binary(url), do: GenServer.call(__MODULE__, {:set_url, url})

  def set_url(_), do: {:error, "Invalid URL type"}

  @spec set_internal_url(String.t()) :: :ok | error()
  def set_internal_url(internal_url) when is_binary(internal_url),
    do: GenServer.call(__MODULE__, {:set_internal_url, internal_url})

  def set_internal_url(_), do: {:error, "Invalid internal URL type"}

  @spec set_keypair(keypair()) :: :ok | error()
  def set_keypair(%{pubkey: pubkey, privkey: privkey} = keypair)
      when is_binary(pubkey) and is_binary(privkey),
      do: GenServer.call(__MODULE__, {:set_keypair, keypair})

  def set_keypair(_), do: {:error, "Invalid keypair types or structure"}

  @spec set_network_id(String.t()) :: :ok | error()
  def set_network_id(network_id) when is_binary(network_id),
    do: GenServer.call(__MODULE__, {:set_network_id, network_id})

  def set_network_id(_), do: {:error, "Invalid network ID type"}

  @spec http_get(String.t()) :: :ok | error()
  def http_get(path) when is_binary(path), do: GenServer.call(__MODULE__, {:http_get, path})

  def http_get(_), do: {:error, "Invalid path type"}

  def handle_call(
        {:configure, client},
        _from,
        _state
      ),
      do: {:reply, :ok, client}

  def handle_call(:get_url, _from, %Client{url: nil} = state),
    do: {:reply, {:error, "URL not configured"}, state}

  def handle_call(:get_url, _from, %Client{url: url} = state), do: {:reply, {:ok, url}, state}

  def handle_call(:get_internal_url, _from, %Client{internal_url: nil} = state),
    do: {:reply, {:error, "Internal URL not configured"}, state}

  def handle_call(:get_internal_url, _from, %Client{internal_url: internal_url} = state),
    do: {:reply, {:ok, internal_url}, state}

  def handle_call(:get_keypair, _from, %Client{keypair: nil} = state),
    do: {:reply, {:error, "Keypair not configured"}, state}

  def handle_call(:get_keypair, _from, %Client{keypair: keypair} = state),
    do: {:reply, {:ok, keypair}, state}

  def handle_call(:get_network_id, _from, %Client{network_id: nil} = state),
    do: {:reply, {:error, "Network ID not configured"}, state}

  def handle_call(:get_network_id, _from, %Client{network_id: network_id} = state),
    do: {:reply, {:ok, network_id}, state}

  def handle_call({:set_url, url}, _from, state), do: {:reply, :ok, %Client{state | url: url}}

  def handle_call({:set_internal_url, internal_url}, _from, state),
    do: {:reply, :ok, %Client{state | internal_url: internal_url}}

  def handle_call({:set_keypair, keypair}, _from, state),
    do: {:reply, :ok, %Client{state | keypair: keypair}}

  def handle_call({:set_network_id, network_id}, _from, state),
    do: {:reply, :ok, %Client{state | network_id: network_id}}

  def handle_call({:http_get, path}, _from, state) do
    case HTTPoison.get(path) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:reply, {:ok, Poison.decode!(body)}, state}

      {:ok, %HTTPoison.Response{body: body}} ->
        {:reply, {:error, Poison.decode!(body)["reason"]}, state}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:reply, {:error, reason}, state}
    end
  end
end
