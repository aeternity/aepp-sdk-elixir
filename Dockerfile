FROM ubuntu:18.04
RUN apt-get -y update && apt-get -y upgrade 

RUN apt-get -y install libsodium-dev

RUN apt-get -y install build-essential

FROM elixir:1.9.4
COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .
RUN mix local.hex --force
RUN mix local.rebar --force

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    iex -S mix