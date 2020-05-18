# Development environment
FROM elixir:1.10-slim AS development

RUN apt-get update \
  && apt-get install -y curl ca-certificates inotify-tools \
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