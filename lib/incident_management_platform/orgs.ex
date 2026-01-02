defmodule IncidentManagementPlatform.Orgs do
  @moduledoc """
  The Orgs context.

  Owns the multi-tenant hierarchy:

  - Organizations → Teams → Services

  Notes:
  - This context is intentionally DB-backed and stateless; Phoenix nodes should remain
    horizontally scalable.
  - Authorization concerns (RBAC) will be layered later; schemas are designed to be
    tenant-scoped via `organization_id`.
  """

  import Ecto.Query, warn: false

  alias IncidentManagementPlatform.Repo
  alias IncidentManagementPlatform.Orgs.{Organization, Team, Service}

  @doc "Fetch an organization by id."
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc "List teams for a given organization."
  def list_teams(organization_id) do
    Team
    |> where([t], t.organization_id == ^organization_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  @doc "List services for a given organization (optionally filtered by team)."
  def list_services(organization_id, opts \\ []) do
    team_id = Keyword.get(opts, :team_id)

    Service
    |> where([s], s.organization_id == ^organization_id)
    |> maybe_where_team(team_id)
    |> order_by([s], asc: s.name)
    |> Repo.all()
  end

  defp maybe_where_team(query, nil), do: query
  defp maybe_where_team(query, team_id), do: where(query, [s], s.team_id == ^team_id)
end
