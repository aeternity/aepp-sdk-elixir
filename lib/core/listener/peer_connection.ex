defmodule Core.Listener.PeerConnection do
  @moduledoc """
  Every instance of this handles a single connection to a peer.
  """

  use GenServer

  require Logger

  alias Core.Listener
  alias Core.Listener.{Peers, Supervisor}
  alias Utils.Hash
  alias Utils.Serialization

  @behaviour :ranch_protocol

  @p2p_protocol_vsn 1

  @msg_fragment 0
  @ping 1
  @micro_header 0
  @key_header 1
  @get_block_txs 7
  @key_block 10
  @micro_block 11
  @block_txs 13
  @p2p_response 100

  @noise_timeout 5000

  @max_packet_size 0x1FF
  @fragment_size 0x1F9
  @fragment_size_bits @fragment_size * 8

  @first_ping_timeout 30_000

  @get_block_txs_version 1
  @ping_version 1
  @share 32
  @difficulty 0
  # don't trigger sync attempt when pinging
  @sync_allowed <<0>>

  @msg_id_size 2
  @hash_size 256

  def start_link(ref, socket, transport, opts) do
    args = [ref, socket, transport, opts]
    {:ok, pid} = :proc_lib.start_link(__MODULE__, :accept_init, args)
    {:ok, pid}
  end

  def start_link(conn_info) do
    GenServer.start_link(__MODULE__, conn_info)
  end

  # called for inbound connections
  def accept_init(ref, socket, :ranch_tcp, opts) do
    :ok = :proc_lib.init_ack({:ok, self()})
    {:ok, {host, _}} = :inet.peername(socket)
    host_bin = host |> :inet.ntoa() |> :binary.list_to_bin()
    genesis_hash = genesis_hash("my_test")
    version = <<@p2p_protocol_vsn::64>>

    state = Map.merge(opts, %{host: host_bin, version: version, genesis: genesis_hash})

    noise_opts = noise_opts(state.privkey, state.pubkey, genesis_hash, version, state.network)
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
    genesis_hash = genesis_hash("my_test")

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

  # called when initiating a connection
  def handle_info(
        :timeout,
        %{
          genesis: genesis,
          version: version,
          pubkey: pubkey,
          privkey: privkey,
          r_pubkey: r_pubkey,
          host: host,
          port: port,
          network: network_id
        } = state
      ) do
    case :gen_tcp.connect(host, port, [:binary, reuseaddr: true, active: false]) do
      {:ok, socket} ->
        noise_opts = noise_opts(privkey, pubkey, r_pubkey, genesis, version, network_id)

        :inet.setopts(socket, active: true)

        case :enoise.connect(socket, noise_opts) do
          {:ok, noise_socket, _status} ->
            new_state = Map.put(state, :status, {:connected, noise_socket})
            peer = %{host: host, pubkey: r_pubkey, port: port, connection: self()}
            :ok = do_ping(noise_socket, network_id)
            Peers.add_peer(peer)
            {:noreply, new_state}

          {:error, _reason} ->
            :gen_tcp.close(socket)
            {:stop, :normal, state}
        end

      {:error, _reason} ->
        {:stop, :normal, state}
    end
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
        {:noise, _,
         <<@msg_fragment::16, fragment_index::16, total_fragments::16, fragment::binary()>>},
        state
      ),
      do: handle_fragment(state, fragment_index, total_fragments, fragment)

  def handle_info(
        {:noise, _, <<type::16, payload::binary()>>},
        %{status: {:connected, socket}, network: network} = state
      ) do
    if type != 9 do
      deserialized_payload = rlp_decode(type, payload)

      case type do
        @p2p_response ->
          # we're only going to be receiving responses for ping
          handle_response(deserialized_payload, network)

        @ping ->
          spawn(fn -> handle_ping(:todo, self(), state) end)

        @key_block ->
          handle_new_key_block(deserialized_payload)

        @micro_block ->
          handle_new_micro_block(deserialized_payload, socket)

        _ ->
          :ok
      end
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("Connection interrupted by peer - #{inspect(state)}")

    Peers.remove_peer(state.r_pubkey)
    {:stop, :normal, state}
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

  defp handle_response(
         %{result: true, type: type, object: object, reason: nil},
         network
       ) do
    case type do
      @ping ->
        handle_ping_msg(object, network)

      @block_txs ->
        handle_block_txs(object)
    end
  end

  defp handle_response(
         %{result: false, type: _type, object: nil, reason: reason},
         _network
       ),
       do: Logger.error(reason)

  defp handle_ping(
         %{
           peers: peers,
           port: port
         } = payload,
         conn_pid,
         %{host: host, r_pubkey: r_pubkey, network: network}
       ) do
    if !Peers.have_peer?(r_pubkey) do
      peer = %{pubkey: r_pubkey, port: port, host: host, connection: conn_pid}
      Peers.add_peer(peer)
    end

    handle_ping_msg(payload, network)

    exclude = Enum.map(peers, fn peer -> peer.pubkey end)

    send_response({:ok, ping_object_fields(network)}, @ping, conn_pid)
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

  defp send_msg_no_response(msg, pid) when byte_size(msg) > @max_packet_size - @msg_id_size do
    number_of_chunks = msg |> byte_size() |> Kernel./(@fragment_size) |> Float.ceil() |> trunc()
    send_chunks(pid, 1, number_of_chunks, msg)
  end

  defp send_msg_no_response(msg, pid), do: GenServer.call(pid, {:send_msg_no_response, msg})

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

  defp send_fragment(fragment, pid), do: GenServer.call(pid, {:send_msg_no_response, fragment})

  defp pack_msg(type, payload), do: <<type::16, rlp_encode(type, payload)::binary>>

  defp handle_ping_msg(
         %{
           genesis_hash: genesis_hash,
           peers: peers
         },
         network
       ) do
    if genesis_hash(network) == genesis_hash do
      Enum.each(peers, fn peer ->
        if !Peers.have_peer?(peer.pubkey) do
          Peers.try_connect(peer)
        end
      end)
    else
      Logger.info("Peer is on a different network")
    end
  end

  defp handle_new_key_block(key_block), do: Listener.notify_for_key_block(key_block)

  defp handle_new_micro_block(
         %{block_info: block_info, hash: hash, tx_hashes: tx_hashes},
         socket
       ) do
    Listener.notify_for_micro_block(block_info)
    do_get_block_txs(hash, tx_hashes, socket)
  end

  defp handle_block_txs(txs) do
    serialized_txs =
      Enum.map(txs, fn {tx, type} -> Serialization.serialize_for_client(tx, type) end)

    Listener.notify_for_txs(serialized_txs)
  end

  defp rlp_encode(type, payload) do
    :todo
  end

  defp rlp_decode(@p2p_response, encoded_response) do
    [_vsn, result, type, reason, object] = :aeser_rlp.decode(encoded_response)
    deserialized_result = bool_bin(result)

    deserialized_type = :binary.decode_unsigned(type)

    deserialized_reason =
      case reason do
        <<>> ->
          nil

        reason ->
          reason
      end

    deserialized_object =
      case object do
        <<>> ->
          nil

        object ->
          rlp_decode(deserialized_type, object)
      end

    %{
      result: deserialized_result,
      type: deserialized_type,
      reason: deserialized_reason,
      object: deserialized_object
    }
  end

  defp rlp_decode(@ping, encoded_ping) do
    [
      _vsn,
      port,
      share,
      genesis_hash,
      _difficulty,
      _best_hash,
      _sync_allowed,
      peers
    ] = :aeser_rlp.decode(encoded_ping)

    %{
      port: :binary.decode_unsigned(port),
      share: :binary.decode_unsigned(share),
      genesis_hash: genesis_hash,
      peers: Peers.rlp_decode_peers(peers)
    }
  end

  defp rlp_decode(@key_block, encoded_key_block) do
    [
      _vsn,
      key_block_bin
    ] = :aeser_rlp.decode(encoded_key_block)

    <<version::32, @key_header::1, _info_flag::1, 0::30, height::64, prev_hash::@hash_size,
      prev_key_hash::@hash_size, root_hash::@hash_size, miner::@hash_size,
      beneficiary::@hash_size, target::32, pow_evidence::1344, nonce::64, time::64,
      info::binary()>> = key_block_bin

    bin_pow_evidence = <<pow_evidence::1344>>

    deserialized_pow_evidence = for <<x::32 <- bin_pow_evidence>>, do: x

    prev_block_type = prev_block_type(prev_hash, prev_key_hash)

    %{
      version: version,
      height: height,
      prev_hash: :aeser_api_encoder.encode(prev_block_type, <<prev_hash::256>>),
      prev_key_hash: :aeser_api_encoder.encode(:key_block_hash, <<prev_key_hash::256>>),
      root_hash: :aeser_api_encoder.encode(:block_state_hash, <<root_hash::256>>),
      miner: :aeser_api_encoder.encode(:account_pubkey, <<miner::256>>),
      beneficiary: :aeser_api_encoder.encode(:account_pubkey, <<beneficiary::256>>),
      target: target,
      pow_evidence: deserialized_pow_evidence,
      nonce: nonce,
      time: time,
      info: :aeser_api_encoder.encode(:contract_bytearray, info)
    }
  end

  defp rlp_decode(@micro_block, encoded_micro_block) do
    [
      _vsn,
      micro_block_bin,
      is_light
    ] = :aeser_rlp.decode(encoded_micro_block)

    light_micro_template = [header: :binary, tx_hashes: [:binary], pof: [:binary]]
    {type, version, _fields} = :aeser_chain_objects.deserialize_type_and_vsn(micro_block_bin)

    [header: header_bin, tx_hashes: tx_hashes, pof: pof] =
      :aeser_chain_objects.deserialize(
        type,
        version,
        light_micro_template,
        micro_block_bin
      )

    <<version::32, @micro_header::1, pof_tag::1, 0::30, height::64, prev_hash::@hash_size,
      prev_key_hash::@hash_size, root_hash::@hash_size, txs_hash::@hash_size, time::64,
      rest::binary()>> = header_bin

    pof_hash_size = pof_tag * 32

    <<pof_hash::size(pof_hash_size), signature::binary>> = rest

    {:ok, header_hash} = Hash.hash(header_bin)

    prev_block_type = prev_block_type(prev_hash, prev_key_hash)

    block_info = %{
      pof_hash: encode_pof_hash(<<pof_hash::size(pof_hash_size)>>),
      signature: :aeser_api_encoder.encode(:signature, signature),
      version: version,
      height: height,
      prev_hash: :aeser_api_encoder.encode(prev_block_type, <<prev_hash::256>>),
      prev_key_hash: :aeser_api_encoder.encode(:key_block_hash, <<prev_key_hash::256>>),
      root_hash: :aeser_api_encoder.encode(:block_state_hash, <<root_hash::256>>),
      txs_hash: :aeser_api_encoder.encode(:block_tx_hash, <<txs_hash::256>>),
      time: time
    }

    %{block_info: block_info, hash: header_hash, tx_hashes: tx_hashes}
  end

  defp rlp_decode(@block_txs, encoded_txs) do
    [
      _vsn,
      block_hash,
      txs
    ] = :aeser_rlp.decode(encoded_txs)

    Enum.map(txs, fn encoded_tx -> decode_tx(encoded_tx) end)
  end

  defp decode_tx(tx) do
    [signatures: signatures, transaction: transaction] = Serialization.deserialize(tx, :signed_tx)
    {type, _version, _fields} = :aeser_chain_objects.deserialize_type_and_vsn(transaction)
    deserialized_tx = Serialization.deserialize(transaction, type)

    {deserialized_tx, type}
  end

  defp do_ping(socket, network_id) do
    ping_rlp = network_id |> ping_object_fields() |> :aeser_rlp.encode()
    msg = <<@ping::16, ping_rlp::binary()>>
    :enoise.send(socket, msg)
  end

  defp do_get_block_txs(block_hash, tx_hashes, socket) do
    get_block_txs_rlp = block_hash |> get_block_txs_fields(tx_hashes) |> :aeser_rlp.encode()

    get_block_txs_msg = <<@get_block_txs::16, get_block_txs_rlp::binary>>

    :ok = :enoise.send(socket, get_block_txs_msg)
  end

  defp ping_object_fields(network_id),
    do: [
      :binary.encode_unsigned(@ping_version),
      :binary.encode_unsigned(Supervisor.port()),
      :binary.encode_unsigned(@share),
      genesis_hash(network_id),
      :binary.encode_unsigned(@difficulty),
      genesis_hash(network_id),
      @sync_allowed,
      []
    ]

  defp get_block_txs_fields(block_hash, tx_hashes),
    do: [:binary.encode_unsigned(@get_block_txs_version), block_hash, tx_hashes]

  defp noise_opts(privkey, pubkey, r_pubkey, genesis_hash, version, network_id) do
    [
      {:rs, :enoise_keypair.new(:dh25519, r_pubkey)}
      | noise_opts(privkey, pubkey, genesis_hash, version, network_id)
    ]
  end

  defp noise_opts(privkey, pubkey, genesis_hash, version, network_id) do
    [
      noise: "Noise_XK_25519_ChaChaPoly_BLAKE2b",
      s: :enoise_keypair.new(:dh25519, privkey, pubkey),
      prologue: <<version::binary(), genesis_hash::binary(), network_id::binary()>>,
      timeout: @noise_timeout
    ]
  end

  defp genesis_hash(:mainnet),
    do:
      <<108, 21, 218, 110, 191, 175, 2, 120, 254, 175, 77, 241, 176, 241, 169, 130, 85, 7, 174,
        123, 154, 73, 75, 195, 76, 145, 113, 63, 56, 221, 87, 131>>

  defp genesis_hash("my_test"),
    do:
      <<174, 36, 148, 219, 224, 173, 204, 138, 98, 177, 222, 19, 81, 20, 248, 121, 34, 251, 150,
        97, 11, 12, 130, 0, 6, 186, 138, 239, 69, 85, 82, 206>>

  defp encode_pof_hash(""), do: "no_fraud"

  defp encode_pof_hash(pof_hash), do: :aeser_api_encoder.encode(:pof_hash, pof_hash)

  defp bool_bin(bool) do
    case bool do
      true ->
        <<1>>

      false ->
        <<0>>

      <<1>> ->
        true

      <<0>> ->
        false
    end
  end

  defp prev_block_type(prev_hash, prev_key_hash) do
    if prev_hash == prev_key_hash do
      :key_block_hash
    else
      :micro_block_hash
    end
  end
end
