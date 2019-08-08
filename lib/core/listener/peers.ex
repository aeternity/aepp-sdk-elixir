defmodule AeppSDK.Core.Listener.Peers do
  @moduledoc false
  use GenServer

  alias AeppSDK.Utils.{Keys, Encoding}
  alias AeppSDK.Core.Listener.PeerConnectionSupervisor

  require Logger

  def start_link(info) do
    peers = %{}

    keypair = Keys.generate_peer_keypair()

    state = %{peers: peers, local_keypair: keypair}
    GenServer.start_link(__MODULE__, {state, info}, name: __MODULE__)
  end

  def init({state, info}) do
    {:ok, {state, info}, 0}
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

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def add_peer(conn_info) do
    GenServer.call(__MODULE__, {:add_peer, conn_info})
  end

  @spec try_connect(map()) :: :ok
  def try_connect(peer_info) do
    GenServer.cast(__MODULE__, {:try_connect, peer_info})
  end

  def handle_info(
        :timeout,
        {state, %{initial_peers: initial_peers, network: network_id, genesis: genesis_hash}}
      ) do
    :ok = connect_to_peers(initial_peers, network_id, genesis_hash)
    {:noreply, state}
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

  def connect_to_peers([], network_id, nil) do
    info = %{network: network_id, genesis: genesis_hash(network_id)}

    network_id |> seed_nodes() |> connect_to_peers(info)
  end

  def connect_to_peers(peers, network_id, genesis_hash) do
    binary_genesis = Encoding.prefix_decode_base58c(genesis_hash)
    info = %{network: network_id, genesis: binary_genesis}

    connect_to_peers(peers, info)
  end

  defp connect_to_peers(peers, info) do
    Enum.each(peers, fn peer ->
      peer |> deserialize_peer() |> Map.merge(info) |> try_connect()
    end)
  end

  defp deserialize_peer(<<"aenode://", rest::binary>>) do
    [pubkey, address] = String.split(rest, "@")
    [host, port] = String.split(address, ":")

    %{
      host: String.to_charlist(host),
      port: String.to_integer(port),
      pubkey: Encoding.prefix_decode_base58c(pubkey)
    }
  end

  def genesis_hash("ae_mainnet"),
    do:
      <<108, 21, 218, 110, 191, 175, 2, 120, 254, 175, 77, 241, 176, 241, 169, 130, 85, 7, 174,
        123, 154, 73, 75, 195, 76, 145, 113, 63, 56, 221, 87, 131>>

  def genesis_hash("ae_uat"),
    do:
      <<123, 173, 180, 20, 178, 230, 65, 254, 59, 198, 234, 129, 117, 11, 11, 80, 142, 52, 238,
        147, 191, 98, 135, 252, 203, 203, 175, 212, 7, 8, 237, 83>>

  defp seed_nodes("ae_mainnet"),
    do: [
      "aenode://pp_2L8A5vSjnkLtfFNpJNgP9HbmGLD7ZAGFxoof47N8L4yyLAyyMi@18.136.37.63:3015",
      "aenode://pp_2gPZjuPnJnTVEbrB9Qgv7f4MdhM4Jh6PD22mB2iBA1g7FRvHTk@52.220.198.72:3015",
      "aenode://pp_tVdaaX4bX54rkaVEwqE81hCgv6dRGPPwEVsiZk41GXG1A4gBN@3.16.242.93:3015",
      "aenode://pp_2mwr9ikcyUDUWTeTQqdu8WJeQs845nYPPqjafjcGcRWUx4p85P@3.17.30.101:3015",
      "aenode://pp_2CAJwwmM2ZVBHYFB6na1M17roQNuRi98k6WPFcoBMfUXvsezVU@13.58.177.66:3015",
      "aenode://pp_7N7dkCbg39MYzQv3vCrmjVNfy6QkoVmJe3VtiZ3HRncvTWAAX@13.53.114.199:3015",
      "aenode://pp_22FndjTkMMXZ5gunCTUyeMPbgoL53smqpM4m1Jz5fVuJmPXm24@13.53.149.181:3015",
      "aenode://pp_Xgsqi4hYAjXn9BmrU4DXWT7jURy2GoBPmrHfiCoDVd3UPQYcU@13.53.164.121:3015",
      "aenode://pp_vTDXS3HJrwJecqnPqX3iRxKG5RBRz9MdicWGy8p9hSdyhAY4S@13.53.77.98:3015"
    ]

  defp seed_nodes("ae_uat"),
    do: [
      "aenode://pp_QU9CvhAQH56a2kA15tCnWPRJ2srMJW8ZmfbbFTAy7eG4o16Bf@52.10.46.160:3015",
      "aenode://pp_2vhFb3HtHd1S7ynbpbFnEdph1tnDXFSfu4NGtq46S2eM5HCdbC@18.195.109.60:3015",
      "aenode://pp_27xmgQ4N1E3QwHyoutLtZsHW5DSW4zneQJ3CxT5JbUejxtFuAu@13.250.162.250:3015",
      "aenode://pp_DMLqy7Zuhoxe2FzpydyQTgwCJ52wouzxtHWsPGo51XDcxc5c8@13.53.161.215:3015"
    ]
end
