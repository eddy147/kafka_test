ARG ELIXIR_VERSION=1.14
ARG BASE_IMAGE=elixir:${ELIXIR_VERSION}-alpine

FROM $BASE_IMAGE as base

WORKDIR /app

# Install Hex + Rebar
RUN apk add -uUv \
  gcc g++ git make \
  && \
    git clone https://github.com/erlang/rebar3.git && \
    cd rebar3 && \
    ./bootstrap
RUN mix do local.hex --force, local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix do deps.get --only prod, deps.compile, compile --warnings-as-errors

COPY config ./config
COPY lib/ ./lib

### Build/release stage
FROM base as releaser
ENV MIX_ENV=prod
RUN mix release

EXPOSE 4000
ENV PORT=4000 \
    MIX_ENV=prod \
    SHELL=/bin/bash

RUN mkdir -p /data

### Deploy stage
FROM $BASE_IMAGE
WORKDIR /app
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
COPY --from=releaser /app/_build/prod/rel/a ./

CMD ["bin/a", "start"]
