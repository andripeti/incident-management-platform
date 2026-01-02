defmodule IncidentManagementPlatformWeb.IncidentWebhookControllerTest do
  use IncidentManagementPlatformWeb.ConnCase, async: true

  alias IncidentManagementPlatform.Orgs.{Organization, Service, Team}
  alias IncidentManagementPlatform.Repo

  test "POST /api/v1/incidents/trigger triggers an incident", %{conn: conn} do
    org = Repo.insert!(%Organization{name: "Acme", slug: "acme-webhook"})
    team = Repo.insert!(%Team{organization_id: org.id, name: "Ops", slug: "ops"})

    service =
      Repo.insert!(%Service{
        organization_id: org.id,
        team_id: team.id,
        name: "API",
        slug: "api",
        integration_key: "webhook-key"
      })

    payload = %{
      "integration_key" => service.integration_key,
      "title" => "Webhook trigger",
      "description" => "Something happened"
    }

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post(~p"/api/v1/incidents/trigger", payload)

    assert %{"incident_id" => _id, "status" => "triggered"} = json_response(conn, 200)
  end

  test "returns 404 for unknown integration key", %{conn: conn} do
    payload = %{"integration_key" => "nope", "title" => "test"}

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post(~p"/api/v1/incidents/trigger", payload)

    assert %{"error" => "unknown_integration_key"} = json_response(conn, 404)
  end
end
