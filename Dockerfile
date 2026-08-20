ARG ELIXIR_VERSION=1.20.2
ARG OTP_VERSION=29.0.4
ARG DEBIAN_VERSION=trixie-20260713-slim

# ============================================================
# Build
# ============================================================
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS build


RUN apt-get update -y && apt-get install -y --no-install-recommends build-essential git curl 

RUN mix local.hex --force && \
mix local.rebar --force

RUN mkdir /app
WORKDIR /app


# Install dependencies first so Docker can cache this layer
COPY mix.exs mix.lock ./

ENV MIX_ENV=prod
ENV ERL_FLAGS="+JPperf true"

RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application
COPY config config
COPY lib lib
COPY priv priv

# Phoenix assets
COPY assets assets

RUN mix assets.deploy

# Compile
RUN mix compile

# Build release
RUN mix release


# ============================================================
# Runtime
# ============================================================
FROM debian:${DEBIAN_VERSION} AS runtime

RUN apt-get clean all && apt-get update && apt-get install -y curl openssl

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV MIX_ENV=prod
ENV PHX_SERVER=true

WORKDIR /app

COPY --from=build /app/_build/prod/rel/pauper_league ./
COPY --from=build /app/config/start.sh /

ENTRYPOINT ["/start.sh"]