defmodule Core.Listener.Worker.Supervisor do
  use Supervisor

  def start_link(parent_pid) do
    Supervisor.start_link(__MODULE__, parent_pid)
  end

  def init(parent_pid) do
    children = [
      {Core.Listener.Worker, parent_pid}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
