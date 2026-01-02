defmodule IncidentManagementPlatform.Incidents.Incident do
  @moduledoc "An incident represents an ongoing disruption requiring response."

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc "Incident lifecycle states."
  @type status :: :triggered | :acknowledged | :resolved

  schema "incidents" do
    field :title, :string
    field :description, :string

    field :status, Ecto.Enum,
      values: [:triggered, :acknowledged, :resolved],
      default: :triggered

    field :dedup_key, :string

    field :triggered_at, :utc_datetime
    field :acknowledged_at, :utc_datetime
    field :resolved_at, :utc_datetime

    belongs_to :organization, IncidentManagementPlatform.Orgs.Organization
    belongs_to :service, IncidentManagementPlatform.Orgs.Service

    has_many :events, IncidentManagementPlatform.Incidents.IncidentEvent

    timestamps(type: :utc_datetime)
  end

  def create_changeset(incident, attrs) do
    incident
    |> cast(attrs, [:organization_id, :service_id, :title, :description, :dedup_key])
    |> validate_required([:organization_id, :service_id, :title])
    |> validate_length(:title, min: 3, max: 200)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:service_id)
  end

  def transition_changeset(incident, attrs) do
    incident
    |> cast(attrs, [:status, :acknowledged_at, :resolved_at])
    |> validate_required([:status])
  end
end
