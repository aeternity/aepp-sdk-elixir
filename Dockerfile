FROM elixir:1.9-alpine

RUN apk add --no-cache libsodium-dev git g++ make

COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && mix compile

RUN apk del g++ make

CMD ["iex", "-S", "mix"]