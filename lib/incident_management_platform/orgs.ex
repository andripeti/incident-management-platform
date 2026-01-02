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

  alias Ecto.Multi

  alias IncidentManagementPlatform.Accounts.Scope
  alias IncidentManagementPlatform.Repo
  alias IncidentManagementPlatform.Orgs.{Organization, OrganizationMembership, Service, Team}

  @type role :: :admin | :responder | :viewer

  @doc "List organizations the current user belongs to."
  def list_organizations(%Scope{user: user}) when not is_nil(user) do
    Organization
    |> join(:inner, [o], m in OrganizationMembership, on: m.organization_id == o.id)
    |> where([_o, m], m.user_id == ^user.id)
    |> order_by([o], asc: o.name)
    |> Repo.all()
  end

  def list_organizations(_scope), do: []

  @doc "Fetch an organization and ensure the current user has membership."
  def get_organization_for_user!(%Scope{user: user} = scope, organization_id)
      when not is_nil(user) do
    _membership = get_membership!(scope, organization_id)
    Repo.get!(Organization, organization_id)
  end

  @doc "Create a new organization and grant the creator the :admin role."
  def create_organization(%Scope{user: user}, attrs) when not is_nil(user) do
    Multi.new()
    |> Multi.insert(:organization, Organization.changeset(%Organization{}, attrs))
    |> Multi.insert(:membership, fn %{organization: org} ->
      %OrganizationMembership{organization_id: org.id, user_id: user.id}
      |> OrganizationMembership.changeset(%{"role" => "admin"})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: org}} -> {:ok, org}
      {:error, :organization, changeset, _changes} -> {:error, changeset}
      {:error, :membership, changeset, _changes} -> {:error, changeset}
    end
  end

  def create_organization(_scope, _attrs), do: {:error, :unauthenticated}

  @doc "List teams for an organization the user has access to."
  def list_teams(scope, organization_id) do
    _membership = get_membership!(scope, organization_id)

    Team
    |> where([t], t.organization_id == ^organization_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  @doc "Create a team within an organization. Requires :admin role."
  def create_team(scope, organization_id, attrs) do
    membership = get_membership!(scope, organization_id)

    if membership.role != :admin do
      {:error, :forbidden}
    else
      %Team{organization_id: organization_id}
      |> Team.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc "List services for an organization (optionally filtered by team)."
  def list_services(scope, organization_id, opts \\ []) do
    _membership = get_membership!(scope, organization_id)

    team_id = Keyword.get(opts, :team_id)

    Service
    |> where([s], s.organization_id == ^organization_id)
    |> maybe_where_team(team_id)
    |> preload([s], [:team])
    |> order_by([s], asc: s.name)
    |> Repo.all()
  end

  @doc "Create a service within an organization. Requires :admin role."
  def create_service(scope, organization_id, attrs) do
    membership = get_membership!(scope, organization_id)

    if membership.role != :admin do
      {:error, :forbidden}
    else
      with {:ok, team_id} <- cast_int(Map.get(attrs, "team_id")),
           %Team{} = team <- Repo.get_by(Team, id: team_id, organization_id: organization_id) do
        integration_key = generate_integration_key()

        case(
          %Service{organization_id: organization_id, team_id: team.id}
          |> Service.changeset(Map.put(attrs, "integration_key", integration_key))
          |> Repo.insert()
        ) do
          {:ok, service} -> {:ok, Repo.preload(service, :team)}
          other -> other
        end
      else
        :error -> {:error, :invalid_team}
        nil -> {:error, :invalid_team}
      end
    end
  end

  @doc "Get the user's role within an organization (or nil if no membership)."
  @spec get_role(Scope.t(), Ecto.UUID.t() | pos_integer() | binary()) :: role() | nil
  def get_role(%Scope{} = scope, organization_id) do
    case get_membership(scope, organization_id) do
      %OrganizationMembership{role: role} -> role
      nil -> nil
    end
  end

  def get_role(_scope, _organization_id), do: nil

  defp maybe_where_team(query, nil), do: query
  defp maybe_where_team(query, team_id), do: where(query, [s], s.team_id == ^team_id)

  defp cast_int(nil), do: :error

  defp cast_int(val) when is_integer(val), do: {:ok, val}

  defp cast_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, ""} -> {:ok, i}
      _ -> :error
    end
  end

  defp generate_integration_key do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp get_membership(%Scope{user: user}, organization_id) when not is_nil(user) do
    Repo.get_by(OrganizationMembership, organization_id: organization_id, user_id: user.id)
  end

  defp get_membership(_scope, _organization_id), do: nil

  defp get_membership!(%Scope{user: user}, organization_id) when not is_nil(user) do
    Repo.get_by!(OrganizationMembership, organization_id: organization_id, user_id: user.id)
  end
end
