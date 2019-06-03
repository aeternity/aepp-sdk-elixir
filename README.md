# Aepp SDK Elixir

Elixir SDK targeting the [æternity node](https://github.com/aeternity/aeternity) implementation.

## Prerequisites
Ensure that you have [Elixir](https://elixir-lang.org/install.html) and [wget](https://www.gnu.org/software/wget/) installed.

## Setup the project

```
git clone https://github.com/aeternity/aepp-sdk-elixir
mix build_api v1.0.0-elixir v3.0.0
```
Where:
 - `v1.0.0-elixir` - OpenAPI client [generator](https://github.com/aeternity/openapi-generator/tree/elixir-adjustment#openapi-generator) [release](https://github.com/aeternity/openapi-generator/releases) version.
 - `v3.0.0` - Aeternity node API [specification file](https://github.com/aeternity/aeternity/blob/v3.0.0/config/swagger.yaml).

## Example usage
Functions that make requests to a node require a client as their first parameter. A client is defined like so:
```elixir
Core.Client.new(
  %{
    public: "ak_aNC4vAk5RDQdDpWdReL9ou37fBvGVYoGDah6cL1GTva3WV3JU",
    secret:
      "e647a7711a2ec9476033984e2805c0631730f402eae62bf23675084fd02034bc4bc297d3b621b99a229c3f9a3c0db1ce98573fc5d7098be2603357ba53340e2f"
  }, # keypair
  "ae_uat", # network ID
  "http://localhost:3013/v2", # external URL
  "http://localhost:3113/v2" # internal URL
)
```

**Deploy a smart contract:**
``` elixir
iex> keypair = Utils.Keys.generate_keypair()
iex> network_id = "ae_uat"
iex> url = "https://sdk-testnet.aepps.com/v2"
iex> internal_url = "https://sdk-testnet.aepps.com/v2"
iex> client = Core.Client.new(keypair, network_id, url, internal_url)
iex> source_code = "contract Number =\n  record state = { number : int }\n  function init(x : int) =\n    { number = x }\n  function add_to_number(x : int) = state.number + x"
iex> init_args = ["42"]
iex> Core.Contract.deploy(client, source_code, init_args)
{:ok, "ct_2sZ43ScybbzKkd4iFMuLJw7uQib1dpUB8VDi9pLkALV5BpXXNR"}
```
