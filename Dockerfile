FROM elixir:1.9.4
ENV LIBSODIUM_VER=1.0.16

RUN apt update && \
    apt install -y wget

RUN mkdir -p libsodium-src && \
    wget -O libsodium-src.tar.gz https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VER/libsodium-$LIBSODIUM_VER.tar.gz && tar -zxf libsodium-src.tar.gz -C libsodium-src --strip-components=1 && \
    libsodium-src/configure && make -j$(nproc) && make install && ldconfig

# lib folder should include generated low-level API modules
COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && mix compile

CMD ["iex", "-S", "mix"]