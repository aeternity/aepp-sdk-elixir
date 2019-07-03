defmodule Core.Listener.Peers do
  use GenServer

  alias Utils.Keys
  alias Core.Listener.PeerConnection
  alias Core.Listener.PeerConnectionSupervisor

  require Logger

  def start_link(network) do
    peers = %{}

    keypair = Keys.generate_peer_keypair()

    state = %{peers: peers, local_keypair: keypair, network: network}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def rlp_decode_peers(encoded_peers) do
    Enum.map(encoded_peers, fn encoded_peer ->
      [host, port_bin, pubkey] = :aeser_rlp.decode(encoded_peer)

      %{
        host: to_charlist(host),
        port: :binary.decode_unsigned(port_bin),
        pubkey: pubkey
      }
    end)
  end

  def remove_peer(pubkey) do
    GenServer.call(__MODULE__, {:remove_peer, pubkey})
  end

  def have_peer?(peer_pubkey) do
    GenServer.call(__MODULE__, {:have_peer?, peer_pubkey})
  end

  def network(), do: GenServer.call(__MODULE__, :network)

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def add_peer(conn_info) do
    GenServer.call(__MODULE__, {:add_peer, conn_info})
  end

  @spec try_connect(map()) :: :ok
  def try_connect(peer_info) do
    GenServer.cast(__MODULE__, {:try_connect, Map.put(peer_info, :network, "my_test")})
  end

  def handle_call({:remove_peer, pubkey}, _from, %{peers: peers} = state) do
    updated_peers = Map.delete(peers, pubkey)
    updated_state = %{state | peers: updated_peers}
    {:reply, :ok, updated_state}
  end

  def handle_call({:have_peer?, peer_pubkey}, _from, %{peers: peers} = state) do
    have_peer = Map.has_key?(peers, peer_pubkey)
    {:reply, have_peer, state}
  end

  def handle_call(:network, _from, state), do: {:reply, state.network, state}

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call(
        {:add_peer, %{pubkey: pubkey} = peer_info},
        _from,
        %{peers: peers} = state
      ) do
    updated_peers = Map.put(peers, pubkey, peer_info)
    updated_state = %{state | peers: updated_peers}
    {:reply, :ok, updated_state}
  end

  def handle_cast(
        {:try_connect, peer_info},
        %{peers: peers, local_keypair: %{secret: privkey, public: pubkey}} = state
      ) do
    if peer_info.pubkey != pubkey do
      case Map.has_key?(peers, peer_info.pubkey) do
        false ->
          conn_info =
            Map.merge(peer_info, %{r_pubkey: peer_info.pubkey, privkey: privkey, pubkey: pubkey})

          {:ok, _pid} = PeerConnectionSupervisor.start_peer_connection(conn_info)
          {:noreply, state}

        true ->
          Logger.error(fn -> "Won't add #{inspect(peer_info)}, already in peer list" end)
          {:noreply, state}
      end
    else
      Logger.info("Can't add ourself")
      {:noreply, state}
    end
  end
end
