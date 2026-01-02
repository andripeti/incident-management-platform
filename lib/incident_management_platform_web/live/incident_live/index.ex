defmodule IncidentManagementPlatformWeb.IncidentLive.Index do
  use IncidentManagementPlatformWeb, :live_view

  alias IncidentManagementPlatform.Incidents
  alias IncidentManagementPlatform.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-5xl px-4 py-10 space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div class="space-y-1">
            <.link
              navigate={~p"/orgs/#{@organization.id}"}
              class="text-sm text-zinc-600 hover:underline"
            >
              ← Back
            </.link>
            <h1 class="text-2xl font-semibold tracking-tight">Incidents</h1>

            <p class="text-sm text-zinc-600">Incidents for {@organization.name}.</p>
          </div>

          <div class="text-xs text-zinc-500">Trigger via API: `POST /api/v1/incidents/trigger`</div>
        </div>

        <div id="incidents" class="space-y-2" phx-update="stream">
          <div class="hidden only:block rounded-lg border border-zinc-200 bg-white p-4 text-sm text-zinc-600">
            No incidents yet.
          </div>

          <.link
            :for={{dom_id, incident} <- @streams.incidents}
            id={dom_id}
            navigate={~p"/orgs/#{@organization.id}/incidents/#{incident.id}"}
            class="block rounded-lg border border-zinc-200 bg-white p-4 hover:bg-zinc-50 transition"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="space-y-1">
                <div class="font-medium">{incident.title}</div>

                <div class="text-xs text-zinc-500">Service: {incident.service.name}</div>
              </div>
              <span class={status_badge_class(incident.status)}>{incident.status}</span>
            </div>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"org_id" => organization_id}, _session, socket) do
    organization = Orgs.get_organization_for_user!(socket.assigns.current_scope, organization_id)
    incidents = Incidents.list_incidents(organization.id, preload: [:service])

    socket =
      socket
      |> assign(:organization, organization)
      |> stream(:incidents, incidents)

    {:ok, socket}
  end

  defp status_badge_class(:triggered), do: "text-xs rounded-full px-2 py-1 bg-red-50 text-red-700"

  defp status_badge_class(:acknowledged),
    do: "text-xs rounded-full px-2 py-1 bg-amber-50 text-amber-700"

  defp status_badge_class(:resolved),
    do: "text-xs rounded-full px-2 py-1 bg-emerald-50 text-emerald-700"
end
