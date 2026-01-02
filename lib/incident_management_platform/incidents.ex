defmodule IncidentManagementPlatform.Incidents do
  @moduledoc """
  The Incidents context.

  Incidents are the core operational entities. Postgres remains the source of truth.
  Real-time updates are delivered through Phoenix PubSub and LiveView.

  OTP workflow processes will be added in a later step; this context will expose a
  minimal API for creating and transitioning incidents.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias IncidentManagementPlatform.Accounts.Scope
  alias IncidentManagementPlatform.Orgs
  alias IncidentManagementPlatform.Orgs.Service
  alias IncidentManagementPlatform.Repo
  alias IncidentManagementPlatform.Incidents.{Incident, IncidentEvent}

  @doc "Fetch an incident by id."
  def get_incident!(id), do: Repo.get!(Incident, id)

  @doc "List incidents for an organization, newest first."
  def list_incidents(organization_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    preload = Keyword.get(opts, :preload, [])

    Incident
    |> where([i], i.organization_id == ^organization_id)
    |> order_by([i], desc: i.inserted_at)
    |> limit(^limit)
    |> preload(^preload)
    |> Repo.all()
  end

  @doc "List events for an incident (activity feed)."
  def list_incident_events(incident_id) do
    IncidentEvent
    |> where([e], e.incident_id == ^incident_id)
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end

  @doc "Trigger (or dedupe) an incident using a service integration key (unauthenticated API)."
  def trigger_incident_by_integration_key(%{"integration_key" => integration_key} = attrs)
      when is_binary(integration_key) do
    service = Repo.get_by(Service, integration_key: integration_key)

    if is_nil(service) do
      {:error, :not_found}
    else
      title = Map.get(attrs, "title")
      description = Map.get(attrs, "description")
      dedup_key = Map.get(attrs, "dedup_key")

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      case find_open_dedup(service.id, dedup_key) do
        %Incident{} = incident ->
          {:ok, _event} =
            %IncidentEvent{}
            |> IncidentEvent.changeset(%{
              organization_id: incident.organization_id,
              incident_id: incident.id,
              action: "deduped",
              message: title,
              metadata: %{"source" => "api"}
            })
            |> Repo.insert()

          {:ok, incident}

        nil ->
          multi =
            Multi.new()
            |> Multi.insert(
              :incident,
              Incident.create_changeset(%Incident{}, %{
                organization_id: service.organization_id,
                service_id: service.id,
                title: title,
                description: description,
                dedup_key: dedup_key,
                triggered_at: now
              })
            )
            |> Multi.insert(:event, fn %{incident: incident} ->
              IncidentEvent.changeset(%IncidentEvent{}, %{
                organization_id: incident.organization_id,
                incident_id: incident.id,
                action: "triggered",
                message: title,
                metadata: %{"source" => "api"},
                actor_type: "system"
              })
            end)

          case Repo.transaction(multi) do
            {:ok, %{incident: incident}} -> {:ok, incident}
            {:error, :incident, changeset, _changes} -> {:error, changeset}
            {:error, :event, changeset, _changes} -> {:error, changeset}
          end
      end
    end
  end

  def trigger_incident_by_integration_key(_attrs) do
    {:error,
     Incident.create_changeset(%Incident{}, %{organization_id: nil, service_id: nil, title: nil})}
  end

  @doc "Fetch an incident ensuring the user belongs to the org."
  def get_incident_for_user!(%Scope{} = scope, organization_id, incident_id) do
    if is_nil(Orgs.get_role(scope, organization_id)) do
      raise Ecto.NoResultsError, queryable: Incident
    end

    Incident
    |> where([i], i.organization_id == ^organization_id and i.id == ^to_int!(incident_id))
    |> preload([:service])
    |> Repo.one!()
  end

  @doc "True if the current scope can acknowledge/resolve incidents in the org."
  def can_respond?(%Scope{} = scope, organization_id) do
    Orgs.get_role(scope, organization_id) in [:admin, :responder]
  end

  def can_respond?(_scope, _organization_id), do: false

  @doc "Acknowledge an incident (requires :admin or :responder)."
  def acknowledge_incident(%Scope{} = scope, organization_id, incident_id) do
    if can_respond?(scope, organization_id) do
      transition(scope, organization_id, incident_id, :acknowledged)
    else
      {:error, :forbidden}
    end
  end

  @doc "Resolve an incident (requires :admin or :responder)."
  def resolve_incident(%Scope{} = scope, organization_id, incident_id) do
    if can_respond?(scope, organization_id) do
      transition(scope, organization_id, incident_id, :resolved)
    else
      {:error, :forbidden}
    end
  end

  defp transition(%Scope{user: user}, organization_id, incident_id, status)
       when status in [:acknowledged, :resolved] do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    incident =
      Repo.one(
        from i in Incident,
          where: i.organization_id == ^organization_id and i.id == ^to_int!(incident_id)
      )

    if is_nil(incident) do
      {:error, :not_found}
    else
      changes =
        case status do
          :acknowledged -> %{status: :acknowledged, acknowledged_at: now}
          :resolved -> %{status: :resolved, resolved_at: now}
        end

      multi =
        Multi.new()
        |> Multi.update(:incident, Incident.transition_changeset(incident, changes))
        |> Multi.insert(:event, fn %{incident: updated} ->
          IncidentEvent.changeset(%IncidentEvent{}, %{
            organization_id: updated.organization_id,
            incident_id: updated.id,
            action: Atom.to_string(status),
            actor_type: "user",
            actor_id: user.id
          })
        end)

      case Repo.transaction(multi) do
        {:ok, %{incident: updated}} -> {:ok, updated}
        {:error, :incident, _changeset, _changes} -> {:error, :not_found}
        {:error, :event, _changeset, _changes} -> {:error, :not_found}
      end
    end
  end

  defp find_open_dedup(_service_id, nil), do: nil

  defp find_open_dedup(service_id, dedup_key) do
    Repo.one(
      from i in Incident,
        where:
          i.service_id == ^service_id and i.dedup_key == ^dedup_key and i.status != :resolved,
        order_by: [desc: i.inserted_at],
        limit: 1
    )
  end

  defp to_int!(val) when is_integer(val), do: val

  defp to_int!(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, ""} -> i
      _ -> raise ArgumentError, "expected integer id"
    end
  end
end
