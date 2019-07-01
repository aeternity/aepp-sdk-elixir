ExUnit.start()
alias Core.Listener

p = %{
  host: 'localhost',
  port: 3015,
  pubkey:
    <<113, 45, 249, 14, 4, 83, 135, 54, 199, 193, 76, 89, 131, 53, 173, 229, 99, 172, 148, 29, 71,
      78, 9, 228, 39, 222, 212, 125, 242, 189, 165, 13>>
}

Listener.Supervisor.start_link(:testnet)
Listener.Peers.try_connect(p)
