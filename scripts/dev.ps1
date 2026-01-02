$ErrorActionPreference = 'Stop'

# Ensure docker is available
docker version | Out-Null

# Start services
cd $PSScriptRoot\..
docker compose up --build
