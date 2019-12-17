FROM elixir:1.9.4
ENV LIBSODIUM_VER=1.0.16

RUN mkdir -p libsodium-src
RUN wget -O libsodium-src.tar.gz https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VER/libsodium-$LIBSODIUM_VER.tar.gz && tar -zxf libsodium-src.tar.gz -C libsodium-src --strip-components=1
RUN mv libsodium-src .libsodium && cd .libsodium
RUN .libsodium/configure && make -j$(nproc) && make install
COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .
RUN mix local.hex --force
RUN mix local.rebar --force

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release
    
RUN APP_NAME="aepp_sdk_elixir"  && \
    mkdir /export && \
    mv _build/prod/rel/$APP_NAME/ /export 


CMD ["bash", "export/aepp_sdk_elixir/bin/aepp_sdk_elixir", "start_iex"]