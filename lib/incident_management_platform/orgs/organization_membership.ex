defmodule IncidentManagementPlatform.Orgs.OrganizationMembership do
  @moduledoc """
  Links a user to an organization with a role.

  This is the foundation for multi-tenant RBAC.

  Roles:
  - `:admin` can manage org structure (teams/services) and incidents
  - `:responder` can acknowledge/resolve incidents
  - `:viewer` can view incidents and dashboards
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type role :: :admin | :responder | :viewer

  schema "organization_memberships" do
    field :role, Ecto.Enum, values: [:admin, :responder, :viewer], default: :viewer

    belongs_to :organization, IncidentManagementPlatform.Orgs.Organization
    belongs_to :user, IncidentManagementPlatform.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:organization_id, :user_id])
  end
end
