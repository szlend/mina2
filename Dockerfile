# Development environment
FROM elixir:1.10-slim AS development

RUN apt-get update \
  && apt-get install -y curl ca-certificates inotify-tools \
  && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install -y nodejs \
  && mix do local.hex --force, local.rebar --force \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
