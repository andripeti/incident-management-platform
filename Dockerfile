FROM elixir:1.19.4-otp-28

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ca-certificates \
    curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Speed up container boot by caching deps.
COPY mix.exs mix.lock ./
RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get

COPY . .

EXPOSE 4000
