# Aepp SDK Elixir

Elixir SDK targeting the [æternity node](https://github.com/aeternity/aeternity) implementation.

## Prerequisites
Ensure that you have [Elixir](https://elixir-lang.org/install.html) and [wget](https://www.gnu.org/software/wget/) installed.

## Setup the project

```
git clone https://github.com/aeternity/aepp-sdk-elixir
mix build_api v1.2.0-elixir v4.2.1
```
Where:
 - `v1.2.0-elixir` - OpenAPI client [generator](https://github.com/aeternity/openapi-generator/tree/elixir-adjustment#openapi-generator) [release](https://github.com/aeternity/openapi-generator/releases) version.
 - `v4.2.1` - Aeternity node API [specification file](https://github.com/aeternity/aeternity/blob/v4.2.1/config/swagger.yaml).

## Usage
An installation and usage guide can be found [here](https://github.com/aeternity/aepp-sdk-elixir/tree/master/examples/usage.md).
