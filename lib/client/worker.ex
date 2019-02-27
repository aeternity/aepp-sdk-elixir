defmodule AeppSDKElixir.Client.Worker do

  use GenServer

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def configure(state) do
    GenServer.call(__MODULE__, {:configure, state})
  end

  def get_url do
    GenServer.call(__MODULE__, :get_url)
  end

  def get_internal_url do
    GenServer.call(__MODULE__, :get_internal_url)
  end

  def get_keypair do
    GenServer.call(__MODULE__, :get_keypair)
  end

  def get_network_id do
    GenServer.call(__MODULE__, :get_network_id)
  end

  def set_url(url) do
    GenServer.call(__MODULE__, {:set_url, url})
  end

  def set_internal_url(internal_url) do
    GenServer.call(__MODULE__, {:set_internal_url, internal_url})
  end

  def set_keypair(%{pubkey: _, privkey: _} = keypair) do
    GenServer.call(__MODULE__, {:set_keypair, keypair})
  end

  def set_network_id(network_id) do
    GenServer.call(__MODULE__, {:set_network_id, network_id})
  end

  def http_get(path) do
    GenServer.call(__MODULE__, {:http_get, path})
  end

  def handle_call(
        {:configure, %{url: _, internal_url: _, keypair: %{pubkey: _, privkey: _}, network_id: _} = config},
        _from,
        _state
      ) do
    {:reply, :ok, config}
  end

  def handle_call(:get_url, _from, %{url: url} = state) do
    {:reply, url, state}
  end

  def handle_call(:get_internal_url, _from, %{internal_url: internal_url} = state) do
    {:reply, internal_url, state}
  end

  def handle_call(:get_keypair, _from, %{keypair: keypair} = state) do
    {:reply, keypair, state}
  end

  def handle_call(:get_network_id, _from, %{network_id: network_id} = state) do
    {:reply, network_id, state}
  end

  def handle_call({:set_url, url}, _from, state) do
    {:reply, :ok, %{state | url: url}}
  end

  def handle_call({:set_internal_url, internal_url}, _from, state) do
    {:reply, :ok, %{state | internal_url: internal_url}}
  end

  def handle_call({:set_keypair, keypair}, _from, state) do
    {:reply, :ok, %{state | keypair: keypair}}
  end

  def handle_call({:set_network_id, network_id}, _from, state) do
    {:reply, :ok, %{state | network_id: network_id}}
  end

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
