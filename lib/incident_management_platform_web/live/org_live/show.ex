defmodule IncidentManagementPlatformWeb.OrgLive.Show do
  use IncidentManagementPlatformWeb, :live_view

  alias IncidentManagementPlatform.Orgs
  alias IncidentManagementPlatform.Orgs.Team

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl px-4 py-10 space-y-8">
        <div class="flex items-start justify-between gap-4">
          <div class="space-y-1">
            <.link navigate={~p"/orgs"} class="text-sm text-zinc-600 hover:underline">← Back</.link>
            <h1 class="text-2xl font-semibold tracking-tight">{@organization.name}</h1>

            <p class="text-sm text-zinc-600">Teams and structure for this organization.</p>
          </div>
        </div>

        <div class="grid gap-8 md:grid-cols-2">
          <section class="space-y-4">
            <h2 class="text-base font-semibold">Teams</h2>

            <div id="teams" class="space-y-2" phx-update="stream">
              <div class="hidden only:block rounded-lg border border-zinc-200 bg-white p-4 text-sm text-zinc-600">
                No teams yet.
              </div>

              <div
                :for={{dom_id, team} <- @streams.teams}
                id={dom_id}
                class="rounded-lg border border-zinc-200 bg-white p-4"
              >
                <div class="font-medium">{team.name}</div>

                <div class="text-xs text-zinc-500">{team.slug}</div>
              </div>
            </div>
          </section>

          <section class="space-y-4">
            <h2 class="text-base font-semibold">Create team</h2>

            <.form for={@form} id="team-create-form" phx-submit="save_team">
              <div class="space-y-4">
                <.input field={@form[:name]} type="text" label="Name" required />
                <.input field={@form[:slug]} type="text" label="Slug" required />
                <.button class="btn btn-primary w-full">Create team</.button>
              </div>
            </.form>

            <p class="text-xs text-zinc-500">Only organization admins can create teams.</p>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => organization_id}, _session, socket) do
    organization = Orgs.get_organization_for_user!(socket.assigns.current_scope, organization_id)
    teams = Orgs.list_teams(socket.assigns.current_scope, organization.id)

    socket =
      socket
      |> assign(:organization, organization)
      |> assign(:form, to_form(Team.changeset(%Team{}, %{})))
      |> stream(:teams, teams)

    {:ok, socket}
  end

  @impl true
  def handle_event("save_team", %{"team" => team_params}, socket) do
    org = socket.assigns.organization

    case Orgs.create_team(socket.assigns.current_scope, org.id, team_params) do
      {:ok, team} ->
        {:noreply, stream_insert(socket, :teams, team)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, "Only organization admins can create teams.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
