# Aepp SDK Elixir

Elixir SDK targeting the [æternity node](https://github.com/aeternity/aeternity) implementation.

## Prerequisites
Ensure that you have [Elixir](https://elixir-lang.org/install.html) and [wget](https://www.gnu.org/software/wget/) installed.

## Setup the project

```
git clone https://github.com/aeternity/aepp-sdk-elixir
mix build_api v1.2.1-elixir v5.0.1 v0.10.0
```
Where:
 - `v1.2.1-elixir` - OpenAPI client [generator](https://github.com/aeternity/openapi-generator/tree/elixir-adjustment#openapi-generator) [release](https://github.com/aeternity/openapi-generator/releases) version.
 - `v5.0.1` - Aeternity node API [specification file](https://github.com/aeternity/aeternity/blob/v5.0.1/apps/aehttp/priv/swagger.yaml).
 - `v0.10.0` - Aeternity middleware API [specification file](https://github.com/aeternity/aepp-middleware/blob/v0.10.0/swagger/swagger.json).

## Usage
An installation and usage guide can be found [here](https://github.com/aeternity/aepp-sdk-elixir/tree/master/examples/usage.md).
