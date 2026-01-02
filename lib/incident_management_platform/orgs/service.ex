defmodule IncidentManagementPlatform.Orgs.Service do
  @moduledoc "A monitored service that can trigger incidents."

  use Ecto.Schema
  import Ecto.Changeset

  schema "services" do
    field :name, :string
    field :slug, :string
    field :integration_key, :string

    belongs_to :organization, IncidentManagementPlatform.Orgs.Organization
    belongs_to :team, IncidentManagementPlatform.Orgs.Team

    timestamps(type: :utc_datetime)
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :slug, :integration_key])
    |> validate_required([:name, :slug, :integration_key])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:team_id)
    |> unique_constraint([:organization_id, :slug])
    |> unique_constraint(:integration_key)
  end
end
