#!/usr/bin/env bash
set -euo pipefail

mix deps.get
mix compile

mix ecto.create
mix ecto.migrate

mix assets.setup
mix assets.build

exec mix phx.server
