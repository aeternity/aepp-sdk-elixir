defmodule AeppSDK.Core.Listener.Supervisor do
  @moduledoc false

  use Supervisor

  alias AeppSDK.Core.Listener
  alias AeppSDK.Core.Listener.Peers
  alias AeppSDK.Core.Listener.PeerConnection
  alias AeppSDK.Core.Listener.PeerConnectionSupervisor
  alias AeppSDK.Utils.Keys

  @acceptors_count 10

  def start_link(info) do
    Supervisor.start_link(__MODULE__, info, name: __MODULE__)
  end

  def init(%{port: port} = info) do
    keypair = Keys.generate_peer_keypair()

    children = [
      PeerConnectionSupervisor,
      {Peers, info},
      :ranch.child_spec(
        :peer_pool,
        @acceptors_count,
        :ranch_tcp,
        [port: port],
        PeerConnection,
        Map.put(
          info,
          :keypair,
          keypair
        )
      ),
      Listener
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
