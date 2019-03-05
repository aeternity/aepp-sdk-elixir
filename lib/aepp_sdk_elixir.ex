defmodule AeppSDKElixir do
  @moduledoc """
  Documentation for AeppSDKElixir.
  """

  use Application

  def start(_type, _args) do
    children = [
      AeppSDKElixir.Client.Worker.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

end
