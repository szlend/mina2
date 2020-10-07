# Development environment
FROM hexpm/elixir:1.11.0-erlang-23.1-ubuntu-focal-20200703 AS development

RUN apt-get update \
  && apt-get install -y curl ca-certificates inotify-tools wait-for-it \
  && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install -y nodejs \
  && mix do local.hex --force, local.rebar --force \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Build environment
FROM development AS build

COPY assets/package.json assets/package-lock.json /app/assets/
RUN npm i --prefix assets

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV
COPY mix.exs mix.lock /app/
COPY config /app/config/
RUN mix do deps.get --only $MIX_ENV, deps.compile

COPY assets /app/assets/
RUN npm run deploy --prefix assets

COPY . /app/
RUN mix do compile, phx.digest

# Release environment
FROM build AS release

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV

RUN mix release --quiet

# Production environment
FROM ubuntu:focal-slim AS production

RUN apt-get update \
  && apt-get install -y openssl locales locales-all \
  && rm -rf /var/lib/apt/lists/*

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV

WORKDIR /app
COPY --from=release /app/_build/$MIX_ENV/rel/mina/ /app

ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV PATH=/app/bin:$PATH

EXPOSE 4000
CMD mina
