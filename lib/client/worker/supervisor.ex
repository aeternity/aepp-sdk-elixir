defmodule AeppSDKElixir.Client.Worker.Supervisor do
  @moduledoc """
  Supervisor responsible for all of the worker modules in his folder
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(_) do
    children = [
      AeppSDKElixir.Client.Worker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
