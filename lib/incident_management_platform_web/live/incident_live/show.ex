defmodule IncidentManagementPlatformWeb.IncidentLive.Show do
  use IncidentManagementPlatformWeb, :live_view

  alias IncidentManagementPlatform.Incidents
  alias IncidentManagementPlatform.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-5xl px-4 py-10 space-y-6">
        <div class="flex items-start justify-between gap-6">
          <div class="space-y-1">
            <.link
              navigate={~p"/orgs/#{@organization.id}/incidents"}
              class="text-sm text-zinc-600 hover:underline"
            >
              ← Back
            </.link>
            <h1 class="text-2xl font-semibold tracking-tight" id="incident-title">
              {@incident.title}
            </h1>

            <p class="text-sm text-zinc-600">Service: {@incident.service.name}</p>
          </div>

          <div class="flex items-center gap-2">
            <span class={status_badge_class(@incident.status)} id="incident-status">
              {@incident.status}
            </span>
            <.button
              :if={@can_respond? and @incident.status == :triggered}
              id="incident-ack-btn"
              phx-click="ack"
              class="btn btn-primary btn-soft"
            >
              Acknowledge
            </.button>
            <.button
              :if={@can_respond? and @incident.status != :resolved}
              id="incident-resolve-btn"
              phx-click="resolve"
              class="btn btn-primary"
            >
              Resolve
            </.button>
          </div>
        </div>

        <section class="rounded-lg border border-zinc-200 bg-white p-4">
          <h2 class="text-base font-semibold">Activity</h2>

          <div id="incident-events" class="mt-4 space-y-2" phx-update="stream">
            <div class="hidden only:block text-sm text-zinc-600">No activity yet.</div>

            <div
              :for={{dom_id, event} <- @streams.events}
              id={dom_id}
              class="rounded-md bg-zinc-50 px-3 py-2"
            >
              <div class="text-xs text-zinc-500">{format_dt(event.inserted_at)}</div>

              <div class="text-sm text-zinc-800">
                {event.action}{if event.message, do: ": " <> event.message, else: ""}
              </div>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"org_id" => organization_id, "id" => incident_id}, _session, socket) do
    organization = Orgs.get_organization_for_user!(socket.assigns.current_scope, organization_id)

    incident =
      Incidents.get_incident_for_user!(socket.assigns.current_scope, organization.id, incident_id)

    events = Incidents.list_incident_events(incident.id)

    can_respond? = Incidents.can_respond?(socket.assigns.current_scope, organization.id)

    socket =
      socket
      |> assign(:organization, organization)
      |> assign(:incident, incident)
      |> assign(:can_respond?, can_respond?)
      |> stream(:events, events)

    {:ok, socket}
  end

  @impl true
  def handle_event("ack", _params, socket) do
    org = socket.assigns.organization
    incident = socket.assigns.incident

    case Incidents.acknowledge_incident(socket.assigns.current_scope, org.id, incident.id) do
      {:ok, updated} ->
        {:noreply, refresh(socket, org.id, updated.id)}

      {:error, :forbidden} ->
        {:noreply,
         put_flash(socket, :error, "You do not have permission to acknowledge incidents.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Incident not found.")}
    end
  end

  @impl true
  def handle_event("resolve", _params, socket) do
    org = socket.assigns.organization
    incident = socket.assigns.incident

    case Incidents.resolve_incident(socket.assigns.current_scope, org.id, incident.id) do
      {:ok, updated} ->
        {:noreply, refresh(socket, org.id, updated.id)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, "You do not have permission to resolve incidents.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Incident not found.")}
    end
  end

  defp refresh(socket, organization_id, incident_id) do
    incident =
      Incidents.get_incident_for_user!(socket.assigns.current_scope, organization_id, incident_id)

    events = Incidents.list_incident_events(incident.id)

    socket
    |> assign(:incident, incident)
    |> stream(:events, events, reset: true)
  end

  defp status_badge_class(:triggered), do: "text-xs rounded-full px-2 py-1 bg-red-50 text-red-700"

  defp status_badge_class(:acknowledged),
    do: "text-xs rounded-full px-2 py-1 bg-amber-50 text-amber-700"

  defp status_badge_class(:resolved),
    do: "text-xs rounded-full px-2 py-1 bg-emerald-50 text-emerald-700"

  defp format_dt(nil), do: ""

  defp format_dt(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end
end
