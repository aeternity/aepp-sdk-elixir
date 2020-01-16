# Aepp SDK Elixir example usage

## Installation
First, add **Aepp SDK Elixir** to your `mix.exs` dependencies:
``` elixir
defp deps do
  [
    {:aepp_sdk_elixir, git: "https://github.com/aeternity/aepp-sdk-elixir.git", tag: "v0.5.3"}
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
### Generate key-pair
In order to operate with **aeternity node**, user has to generate a key-pair.

**Example:**
``` elixir
%{public: _, secret: secret} = AeppSDK.Utils.Keys.generate_keypair()
```

### Store the secret key
Now you have to store your newly generated secret key(for security reasons). 

**Example:**
``` elixir
password = "my_secret_password"
AeppSDK.Utils.Keys.new_keystore(secret, password, name: "aeternity-keystore.json")
```
### Read the keystore
In order to retrieve the secret key from the keystore you have to read the keystore.

**Example:**
``` elixir
AeppSDK.Utils.Keys.read_keystore("aeternity-keystore.json", password)
```

### Define a client:
In order to use functions that require retrieving/sending data to a node, a client structure is needed.

**Example:**
``` elixir
public_key = "ak_jQGc3ECvnQYDZY3i97WSHPigL9tTaVEz1oLBW5J4F1JTKS1g7"
secret_key = "24865931054474805885eec12497ee398bc39bc26917c190ed435e3cd1fa954e6046ef581eef749d492360b1542c7be997b5ddca0d2e510a4312b217998bfc74"
network_id = "ae_uat"
url = "https://sdk-testnet.aepps.com/v2"
internal_url = "https://sdk-testnet.aepps.com/v2"
client = AeppSDK.Client.new(%{public: public_key, secret: secret_key}, network_id, url, internal_url)
```
**NOTE:** If you are using one of these tags `v0.1.0` or `v0.2.0` you have to call the function like: 
``` elixir
Core.Client.new(%{public: public_key, secret: secret_key}, network_id, url, internal_url)
```
The naming conventions were changed. `Core` is `AeppSDK` now and `Utils` is `AeppSDK.Utils`.

Every module and function is documented and you can get the documentation by using, for example:
``` elixir
h AeppSDK.Client
```

## Examples

#### To get current generation:
``` elixir
iex> AeppSDK.Chain.get_current_generation(client)                                                          
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
iex> AeppSDK.Account.balance(client, client.keypair.public) 
{:ok, 811193097223266796526}
```