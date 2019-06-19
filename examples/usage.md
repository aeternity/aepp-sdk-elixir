# Aepp SDK Elixir example usage

## Installation
First, add **Aepp SDK Elixir** to your `mix.exs` dependencies:
``` elixir
defp deps do
  [
    {:aepp_sdk_elixir, git: "https://github.com/aeternity/aepp-sdk-elixir.git", tag: "v0.1.0"}
  ]
end
```

Then, update your dependencies:
``` elixir
mix deps.get
```

Run your project:
``` elixir
iex -S mix
```

## Usage
#### Define a client:
In order to use functions that require retrieving/sending data to a node, a client structure is needed, for example:
``` elixir
public_key = "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU"
secret_key = "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
network_id = "ae_uat"
url = "https://sdk-testnet.aepps.com/v2"
internal_url = "https://sdk-testnet.aepps.com/v2"
client = Core.Client.new(%{public: public_key, secret: secret_key}, network_id, url, internal_url)
```

And now, you are ready to use **Aepp SDK Elixir**.

Every module and function is documented and you can get the documentation by using, for example:
``` elixir
h Core.Client
```

## Examples

#### To get current generation:
``` elixir
iex> Core.Chain.get_current_generation(client)                                                          
{:ok,
 %{
   key_block: %{
     beneficiary: "ak_2iBPH7HUz3cSDVEUWiHg76MZJ6tZooVNBmmxcgVK6VV8KAE688",
     hash: "kh_2jnRkkeFpDMpLfJxZsVdpTtLomNj1sgjcQSoThXL4Zyirca6fT",
     height: 96894,
     info: "cb_AAAAAfy4hFE=",
     miner: "ak_2b1hyRMEjQmYT2GTLS1N9AVcGCqGsf6ng3LHvhnDLUHLbE6s4w",
     nonce: 11449002324963238722,
     pow: [3407814, 16834736, 19393828, 20269880, 28859692, 31569835, 41776618,
      54459124, 56323237, 59364915, 66530222, 74201382, 84361285, 85176466,
      88059514, 100722354, 106955257, 109076253, 140840049, 222311497,
      226497503, 232310835, 240999898, 300530215, 313834856, 323852493,
      325445647, 339271495, 355421106, 356456684, 369648267, 376071535,
      379588007, 404046811, 415371506, 426162172, 428200431, 445577051,
      450889898, 466828929, ...],
     prev_hash: "mh_Vru9EPdyvovkMFADq8ia1AaQ8BZRdTKAwUump4XyBBwy6Yybt",
     prev_key_hash: "kh_VtDLXG82cQYN3qhs3qAtnSnkLBGgZwoPGNsxxAecfT14LrbQa",
     state_hash: "bs_wjWjvoPBWGQoATYbsZYt184chU2CeUyHPtTcLU7vnAuCVgob1",
     target: 538630112,
     time: 1560853362522,
     version: 3
   },
   micro_blocks: []
 }}
```

#### To get an account's balance:
``` elixir
iex> Core.Account.balance(client, client.keypair.public) 
{:ok, 811193097223266796526}
```