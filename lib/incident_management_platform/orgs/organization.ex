defmodule IncidentManagementPlatform.Orgs.Organization do
  @moduledoc "An organization is the tenant boundary."

  use Ecto.Schema
  import Ecto.Changeset

  schema "organizations" do
    field :name, :string
    field :slug, :string

    has_many :memberships, IncidentManagementPlatform.Orgs.OrganizationMembership
    has_many :teams, IncidentManagementPlatform.Orgs.Team
    has_many :services, IncidentManagementPlatform.Orgs.Service

    timestamps(type: :utc_datetime)
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
    |> unique_constraint(:slug)
  end
end
