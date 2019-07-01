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

  def start_link(network) do
    Supervisor.start_link(__MODULE__, network)
  end

  def init(network) do
    keypair = Keys.generate_peer_keypair()

    children = [
      PeerConnectionSupervisor,
      {Peers, network},
      :ranch.child_spec(
        :peer_pool,
        @acceptors_count,
        :ranch_tcp,
        [port: @default_port],
        PeerConnection,
        %{
          port: @default_port,
          keypair: keypair,
          network: network
        }
      ),
      Listener
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def port(), do: @default_port
end
