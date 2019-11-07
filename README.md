# Aepp SDK Elixir

Elixir SDK targeting the [æternity node](https://github.com/aeternity/aeternity) implementation.

## Installation
To start using this project, simply use source code or compiled binaries, provided in our [releases](https://github.com/aeternity/aepp-sdk-elixir/releases).

Or add **Aepp SDK Elixir** to your `mix.exs` dependencies:
``` elixir
defp deps do
  [
    {:aepp_sdk_elixir, git: "https://github.com/aeternity/aepp-sdk-elixir.git", tag: "v0.5.0"}
  ]
end
```

In order to use code from master branch:
1. You will need **Java** and **Maven**:

```
sudo apt-install default-jdk
sudo apt-install maven
```
2. Then, you will have to [set-up the project](https://github.com/aeternity/aepp-sdk-elixir#setup-the-project).

These dependencies are used by our [OpenAPI Code Generator](https://github.com/aeternity/openapi-generator), which builds low-level API calls, needed for [Aeternity Node](https://github.com/aeternity/aeternity) and [Aeternity Middleware](https://github.com/aeternity/aepp-middleware).

## Prerequisites
**Using released versions:**
Ensure that you have [Elixir](https://elixir-lang.org/install.html) and [wget](https://www.gnu.org/software/wget/) installed.

**Using code from master/other branches**, as mentioned before, additionally, you will have to install [Java](https://java.com/en/download/help/download_options.xml) and [Maven](https://maven.apache.org/install.html).

## Setup the project
```
git clone https://github.com/aeternity/aepp-sdk-elixir
mix build_api v1.2.1-elixir v5.0.2 v0.10.0
```
Where:
 - `v1.2.1-elixir` - OpenAPI client [generator](https://github.com/aeternity/openapi-generator/tree/elixir-adjustment#openapi-generator) [release](https://github.com/aeternity/openapi-generator/releases) version.
 - `v5.0.2` - Aeternity node API [specification file](https://github.com/aeternity/aeternity/blob/v5.0.2/apps/aehttp/priv/swagger.yaml).
 - `v0.10.0` - Aeternity middleware API [specification file](https://github.com/aeternity/aepp-middleware/blob/v0.10.0/swagger/swagger.json).

## Implemented functionality
- **Client module**
Consists of definition of a client structure and other helper functions. Client structure helps us collect and manage all data needed to perform various requests to the HTTP endpoints.

- **Account module**

Contains various functions to interact with aeternity account, e.g. getting an account, spending and etc.

- **Chain module**

In chain module we implemented chain-related activities, like getting current blocks, generations, transactions and others.

- **Oracle module**

This module covers oracle-related activities such as: registering a new oracle, querying an oracle, responding from an oracle, extending an oracle, retrieving oracle and queries functionality.

- **Contract module**

Module implements functions needed to: deploy, call, compile Aeternity's Sophia smart contracts.

- **Naming system module**

Naming system module has many functionalities, needed to manipulate Aeternity naming system. It allows developers to: pre-claim, claim, update, transfer and revoke names.

- **Channel module**

Module, containing implemented and tested all channel on-chain transactions and activities. They are: getting channel info by id, opening a channel, depositing to a channel, withdrawing from a channel, closing solo and closing mutually a channel and many others.

- **Noise listener module**

Module, which works with enoise protocol, which is used by Aeternity. Implemented connection between peers and listening for new blocks, transactions and other stuff.

- **Middleware high-level module**

Simple high-module which performs various requests to exposed endpoints in [Aeternity Middleware](https://github.com/aeternity/aepp-middleware) project.

## Usage
An installation (as library) and basic usage guide can be found [here](https://github.com/aeternity/aepp-sdk-elixir/tree/master/examples/usage.md).
