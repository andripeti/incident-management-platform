# IncidentManagementPlatform

## Run locally (Docker)

Prereqs:
- Docker Desktop (or Docker Engine) with `docker compose` available

Start the app (Phoenix + Postgres):

- `docker compose up --build`

Then visit:
- http://localhost:4000/users/register
- Dev mailbox (confirmation emails): http://localhost:4000/dev/mailbox

Stop everything:
- `docker compose down`

Windows shortcut:
- `./scripts/dev.ps1`

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
