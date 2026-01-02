defmodule IncidentManagementPlatform.Orgs.Team do
  @moduledoc "A team groups responders within an organization."

  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :slug, :string

    belongs_to :organization, IncidentManagementPlatform.Orgs.Organization
    has_many :services, IncidentManagementPlatform.Orgs.Service

    timestamps(type: :utc_datetime)
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
    |> foreign_key_constraint(:organization_id)
    |> unique_constraint([:organization_id, :slug])
  end
end
