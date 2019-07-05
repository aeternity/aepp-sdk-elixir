defmodule Core.Listener.Supervisor do
  @moduledoc """
  Supervises the Peers, PeerConnectionSupervisor and ranch acceptor processes
  """

  use Supervisor

  alias Core.Listener
  alias Core.Listener.Peers
  alias Core.Listener.PeerConnection
  alias Core.Listener.PeerConnectionSupervisor
  alias Utils.Keys

  @default_port 3020
  @acceptors_count 10

  def start_link(%{network: _, genesis: _, initial_peers: _} = info) do
    Supervisor.start_link(__MODULE__, info)
  end

  def init(info) do
    keypair = Keys.generate_peer_keypair()

    children = [
      PeerConnectionSupervisor,
      {Peers, info},
      :ranch.child_spec(
        :peer_pool,
        @acceptors_count,
        :ranch_tcp,
        [port: @default_port],
        PeerConnection,
        Map.merge(
          %{port: @default_port, keypair: keypair},
          info
        )
      ),
      Listener
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def port(), do: @default_port
end
