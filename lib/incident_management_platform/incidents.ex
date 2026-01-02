defmodule IncidentManagementPlatform.Incidents do
  @moduledoc """
  The Incidents context.

  Incidents are the core operational entities. Postgres remains the source of truth.
  Real-time updates are delivered through Phoenix PubSub and LiveView.

  OTP workflow processes will be added in a later step; this context will expose a
  minimal API for creating and transitioning incidents.
  """

  import Ecto.Query, warn: false

  alias IncidentManagementPlatform.Repo
  alias IncidentManagementPlatform.Incidents.{Incident, IncidentEvent}

  @doc "Fetch an incident by id."
  def get_incident!(id), do: Repo.get!(Incident, id)

  @doc "List incidents for an organization, newest first."
  def list_incidents(organization_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Incident
    |> where([i], i.organization_id == ^organization_id)
    |> order_by([i], desc: i.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "List events for an incident (activity feed)."
  def list_incident_events(incident_id) do
    IncidentEvent
    |> where([e], e.incident_id == ^incident_id)
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end
end
