defmodule IncidentManagementPlatformWeb.OrgLive.Index do
  use IncidentManagementPlatformWeb, :live_view

  alias IncidentManagementPlatform.Orgs
  alias IncidentManagementPlatform.Orgs.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl px-4 py-10 space-y-8">
        <div class="space-y-2">
          <h1 class="text-2xl font-semibold tracking-tight">Organizations</h1>

          <p class="text-sm text-zinc-600">Create or select an organization to continue.</p>
        </div>

        <div class="grid gap-8 md:grid-cols-2">
          <section class="space-y-4">
            <h2 class="text-base font-semibold">Your organizations</h2>

            <div
              id="org-list"
              class="space-y-2"
              phx-update="stream"
            >
              <div class="hidden only:block rounded-lg border border-zinc-200 bg-white p-4 text-sm text-zinc-600">
                No organizations yet.
              </div>

              <.link
                :for={{dom_id, org} <- @streams.organizations}
                id={dom_id}
                navigate={~p"/orgs/#{org.id}"}
                class="block rounded-lg border border-zinc-200 bg-white p-4 hover:bg-zinc-50 transition"
              >
                <div class="font-medium">{org.name}</div>

                <div class="text-xs text-zinc-500">{org.slug}</div>
              </.link>
            </div>
          </section>

          <section class="space-y-4">
            <h2 class="text-base font-semibold">Create organization</h2>

            <.form for={@form} id="org-create-form" phx-submit="save">
              <div class="space-y-4">
                <.input field={@form[:name]} type="text" label="Name" required />
                <.input field={@form[:slug]} type="text" label="Slug" required />
                <.button class="btn btn-primary w-full">Create organization</.button>
              </div>
            </.form>

            <p class="text-xs text-zinc-500">
              Slug should be lowercase letters, numbers, and hyphens.
            </p>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    organizations = Orgs.list_organizations(socket.assigns.current_scope)

    socket =
      socket
      |> assign(:form, to_form(Organization.changeset(%Organization{}, %{})))
      |> stream(:organizations, organizations)

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"organization" => org_params}, socket) do
    case Orgs.create_organization(socket.assigns.current_scope, org_params) do
      {:ok, org} ->
        {:noreply, push_navigate(socket, to: ~p"/orgs/#{org.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, :unauthenticated} ->
        {:noreply, put_flash(socket, :error, "You must be logged in.")}
    end
  end
end
