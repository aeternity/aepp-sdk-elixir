defmodule Core.Listener.PeerConnection do
  @moduledoc """
  Every instance of this handles a single connection to a peer.
  """

  use GenServer

  require Logger

  alias Core.Listener.{Peers, Supervisor}
  alias Utils.Serialization

  @behaviour :ranch_protocol

  @p2p_protocol_vsn 1

  @msg_fragment 0
  @ping 1
  @block 11

  @noise_timeout 5000

  @max_packet_size 0x1FF
  @fragment_size 0x1F9
  @fragment_size_bits @fragment_size * 8

  @first_ping_timeout 30_000

  @ping_version 1
  @share 32
  @difficulty 0
  # don't trigger sync attempt when pinging
  @sync_allowed 0

  @msg_id_size 2

  def start_link(ref, socket, transport, opts) do
    args = [ref, socket, transport, opts]
    {:ok, pid} = :proc_lib.start_link(__MODULE__, :accept_init, args)
    {:ok, pid}
  end

  def start_link(conn_info) do
    GenServer.start_link(__MODULE__, conn_info)
  end

  def accept_init(ref, socket, :ranch_tcp, opts) do
    :ok = :proc_lib.init_ack({:ok, self()})
    {:ok, {host, _}} = :inet.peername(socket)
    host_bin = host |> :inet.ntoa() |> :binary.list_to_bin()
    genesis_hash = genesis_hash(:testnet)
    version = <<@p2p_protocol_vsn::64>>

    state = Map.merge(opts, %{host: host_bin, version: version, genesis: genesis_hash})

    noise_opts = noise_opts(state.privkey, state.pubkey, genesis_hash, version)
    :ok = :ranch.accept_ack(ref)
    :ok = :ranch_tcp.setopts(socket, [{:active, true}])

    case :enoise.accept(socket, noise_opts) do
      {:ok, noise_socket, noise_state} ->
        r_pubkey = noise_state |> :enoise_hs_state.remote_keys() |> :enoise_keypair.pubkey()
        new_state = Map.merge(state, %{r_pubkey: r_pubkey, status: {:connected, noise_socket}})
        Process.send_after(self(), :first_ping_timeout, @first_ping_timeout)
        :gen_server.enter_loop(__MODULE__, [], new_state)

      {:error, _reason} ->
        :ranch_tcp.close(socket)
    end
  end

  def init(conn_info) do
    genesis_hash = genesis_hash(:testnet)

    updated_con_info =
      Map.merge(conn_info, %{
        version: <<@p2p_protocol_vsn::64>>,
        genesis: genesis_hash
      })

    # trigger a timeout so that a connection is attempted immediately
    {:ok, updated_con_info, 0}
  end

  def handle_call({:send_msg_no_response, msg}, _from, %{status: {:connected, socket}} = state) do
    res = :enoise.send(socket, msg)
    {:reply, res, state}
  end

  def handle_info(
        :first_ping_timeout,
        %{r_pubkey: r_pubkey, status: {:connected, socket}} = state
      ) do
    case Peers.have_peer?(r_pubkey) do
      true ->
        {:noreply, state}

      false ->
        :enoise.close(socket)
        {:stop, :normal, state}
    end
  end

  def handle_info(
        :timeout,
        %{
          genesis: genesis,
          version: version,
          pubkey: pubkey,
          privkey: privkey,
          r_pubkey: r_pubkey,
          host: host,
          port: port
        } = state
      ) do
    case :gen_tcp.connect(host, port, [:binary, reuseaddr: true, active: false]) do
      {:ok, socket} ->
        noise_opts = noise_opts(privkey, pubkey, r_pubkey, genesis, version)

        :inet.setopts(socket, active: true)

        case :enoise.connect(socket, noise_opts) do
          {:ok, noise_socket, _status} ->
            new_state = Map.put(state, :status, {:connected, noise_socket})
            peer = %{host: host, pubkey: r_pubkey, port: port, connection: self()}
            :ok = do_ping(new_state)
            Peers.add_peer(peer)
            {:noreply, new_state}

          {:error, reason} ->
            :gen_tcp.close(socket)
            {:stop, :normal, state}
        end

      {:error, reason} ->
        {:stop, :normal, state}
    end
  end

  def handle_info(
        {:noise, _,
         <<@msg_fragment::16, fragment_index::16, total_fragments::16, fragment::binary()>>},
        state
      ) do
    handle_fragment(state, fragment_index, total_fragments, fragment)
  end

  def handle_info({:noise, _, <<type::16, payload::binary()>> = msg}, state) do
    case type do
      @ping ->
        spawn(fn -> handle_ping(:todo, self(), state) end)

      @block ->
        spawn(fn -> handle_new_block(:todo) end)
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("Connection interrupted by peer - #{inspect(state)}")

    Peers.remove_peer(state.r_pubkey)
    {:stop, :normal, state}
  end

  defp do_ping(%{status: {:connected, socket}}) do
    rlp_ping = :aeser_rlp.encode(ping_object_fields())
    msg = <<@ping::16, rlp_ping::binary()>>
    :enoise.send(socket, msg)
  end

  defp handle_fragment(state, 1, _m, fragment) do
    {:noreply, Map.put(state, :fragments, [fragment])}
  end

  defp handle_fragment(%{fragments: fragments} = state, fragment_index, total_fragments, fragment)
       when fragment_index == total_fragments do
    msg = [fragment | fragments] |> Enum.reverse() |> :erlang.list_to_binary()
    send(self(), {:noise, :unused, msg})
    {:noreply, Map.delete(state, :fragments)}
  end

  defp handle_fragment(%{fragments: fragments} = state, fragment_index, _m, fragment)
       when fragment_index == length(fragments) + 1 do
    {:noreply, %{state | fragments: [fragment | fragments]}}
  end

  defp handle_ping(payload, conn_pid, %{host: host, r_pubkey: r_pubkey}) do
    %{
      peers: peers,
      port: port
    } = payload

    if !Peers.have_peer?(r_pubkey) do
      peer = %{pubkey: r_pubkey, port: port, host: host, connection: conn_pid}
      Peers.add_peer(peer)
    end

    handle_ping_msg(payload, conn_pid)

    exclude = Enum.map(peers, fn peer -> peer.pubkey end)

    send_response({:ok, ping_object_fields()}, @ping, conn_pid)
  end

  defp send_response(result, type, pid) do
    payload =
      case result do
        {:ok, object} ->
          %{result: true, type: type, reason: nil, object: object}

        {:error, reason} ->
          %{result: false, type: type, reason: reason, object: nil}
      end

    @p2p_response
    |> pack_msg(payload)
    |> send_msg_no_response(pid)
  end

  defp send_request_msg(msg, pid), do: GenServer.call(pid, {:send_request_msg, msg})

  defp send_msg_no_response(msg, pid) when byte_size(msg) > @max_packet_size - @msg_id_size do
    number_of_chunks = msg |> byte_size() |> Kernel./(@fragment_size) |> Float.ceil() |> trunc()
    send_chunks(pid, 1, number_of_chunks, msg)
  end

  defp send_chunks(pid, fragment_index, total_fragments, msg)
       when fragment_index == total_fragments do
    send_fragment(
      <<@msg_fragment::16, fragment_index::16, total_fragments::16, msg::binary()>>,
      pid
    )
  end

  defp send_chunks(
         pid,
         fragment_index,
         total_fragments,
         <<chunk::@fragment_size_bits, rest::binary()>>
       ) do
    send_fragment(
      <<@msg_fragment::16, fragment_index::16, total_fragments::16, chunk::@fragment_size_bits>>,
      pid
    )

    send_chunks(pid, fragment_index + 1, total_fragments, rest)
  end

  defp send_msg_no_response(msg, pid), do: GenServer.call(pid, {:send_msg_no_response, msg})

  defp send_fragment(fragment, pid), do: GenServer.call(pid, {:send_msg_no_response, fragment})

  defp pack_msg(type, payload), do: <<type::16, rlp_encode(type, payload)::binary>>

  defp rlp_encode(type, payload) do
    :todo
  end

  defp handle_ping_msg(
         %{
           genesis_hash: genesis_hash,
           best_hash: best_hash,
           difficulty: difficulty,
           peers: peers
         },
         conn_pid
       ) do
    if genesis_hash(:testnet) == genesis_hash do
      Enum.each(peers, fn peer ->
        if !Peers.have_peer?(peer.pubkey) do
          Peers.try_connect(peer)
        end
      end)
    else
      Logger.info("Peer is on a different network")
    end
  end

  defp handle_response(
         %{result: result, type: type, object: object, reason: reason},
         parent,
         requests
       ) do
    case type do
      @ping ->
        handle_ping_msg(object, parent)

      @block ->
        # TODO: notify subscribers
        handle_new_block(:todo)

      _ ->
        :ok
    end
  end

  defp handle_new_block(block) do
    :todo
  end

  defp ping_object_fields(),
    do: [
      :binary.encode_unsigned(@ping_version),
      :binary.encode_unsigned(Supervisor.port()),
      :binary.encode_unsigned(@share),
      genesis_hash(:testnet),
      :binary.encode_unsigned(@difficulty),
      genesis_hash(:testnet),
      @sync_allowed,
      []
    ]

  defp noise_opts(privkey, pubkey, r_pubkey, genesis_hash, version) do
    [
      {:rs, :enoise_keypair.new(:dh25519, r_pubkey)}
      | noise_opts(privkey, pubkey, genesis_hash, version)
    ]
  end

  defp noise_opts(privkey, pubkey, genesis_hash, version) do
    [
      noise: "Noise_XK_25519_ChaChaPoly_BLAKE2b",
      s: :enoise_keypair.new(:dh25519, privkey, pubkey),
      prologue: <<version::binary(), genesis_hash::binary()>> <> <<"ae_uat">>,
      timeout: @noise_timeout
    ]
  end

  defp genesis_hash(:mainnet),
    do:
      <<108, 21, 218, 110, 191, 175, 2, 120, 254, 175, 77, 241, 176, 241, 169, 130, 85, 7, 174,
        123, 154, 73, 75, 195, 76, 145, 113, 63, 56, 221, 87, 131>>

  defp genesis_hash(:testnet),
    do:
      <<123, 173, 180, 20, 178, 230, 65, 254, 59, 198, 234, 129, 117, 11, 11, 80, 142, 52, 238,
        147, 191, 98, 135, 252, 203, 203, 175, 212, 7, 8, 237, 83>>
end
