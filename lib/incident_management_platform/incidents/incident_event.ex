defmodule IncidentManagementPlatform.Incidents.IncidentEvent do
  @moduledoc """
  Incident-scoped activity feed.

  This is optimized for the incident detail page (LiveView) and is intentionally
  append-only.

  Actor fields are designed to support both system events and user actions. User
  linking will be added during the authentication phase.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "incident_events" do
    field :action, :string
    field :message, :string
    field :metadata, :map

    field :actor_type, :string
    field :actor_id, :integer

    belongs_to :organization, IncidentManagementPlatform.Orgs.Organization
    belongs_to :incident, IncidentManagementPlatform.Incidents.Incident

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :organization_id,
      :incident_id,
      :action,
      :message,
      :metadata,
      :actor_type,
      :actor_id
    ])
    |> validate_required([:organization_id, :incident_id, :action])
    |> validate_length(:action, min: 2, max: 80)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:incident_id)
  end
end
