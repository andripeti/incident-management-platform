defmodule IncidentManagementPlatform.IncidentsTest do
  use IncidentManagementPlatform.DataCase, async: true

  import IncidentManagementPlatform.AccountsFixtures
  import Ecto.Query

  alias IncidentManagementPlatform.Incidents
  alias IncidentManagementPlatform.Orgs.{Organization, OrganizationMembership, Service, Team}
  alias IncidentManagementPlatform.Repo

  describe "incident triggering via integration key" do
    test "creates a triggered incident and event" do
      scope = user_scope_fixture()

      org = Repo.insert!(%Organization{name: "Acme", slug: "acme"})

      Repo.insert!(%OrganizationMembership{
        organization_id: org.id,
        user_id: scope.user.id,
        role: :admin
      })

      team = Repo.insert!(%Team{organization_id: org.id, name: "Ops", slug: "ops"})

      service =
        Repo.insert!(%Service{
          organization_id: org.id,
          team_id: team.id,
          name: "API",
          slug: "api",
          integration_key: "test-key"
        })

      assert {:ok, incident} =
               Incidents.trigger_incident_by_integration_key(%{
                 "integration_key" => service.integration_key,
                 "title" => "Something broke",
                 "description" => "Boom"
               })

      assert incident.organization_id == org.id
      assert incident.service_id == service.id
      assert incident.status == :triggered

      events = Incidents.list_incident_events(incident.id)
      assert Enum.any?(events, &(&1.action == "triggered"))
    end

    test "dedupes when dedup_key matches open incident" do
      org = Repo.insert!(%Organization{name: "Acme2", slug: "acme2"})
      team = Repo.insert!(%Team{organization_id: org.id, name: "Ops", slug: "ops"})

      service =
        Repo.insert!(%Service{
          organization_id: org.id,
          team_id: team.id,
          name: "API",
          slug: "api",
          integration_key: "dedupe-key"
        })

      assert {:ok, incident1} =
               Incidents.trigger_incident_by_integration_key(%{
                 "integration_key" => service.integration_key,
                 "title" => "First",
                 "dedup_key" => "same"
               })

      assert {:ok, incident2} =
               Incidents.trigger_incident_by_integration_key(%{
                 "integration_key" => service.integration_key,
                 "title" => "Second",
                 "dedup_key" => "same"
               })

      assert incident1.id == incident2.id

      events = Incidents.list_incident_events(incident1.id)
      assert Enum.any?(events, &(&1.action == "deduped"))
    end
  end

  describe "incident transitions" do
    test "acknowledge/resolve require responder or admin" do
      scope = user_scope_fixture()

      org = Repo.insert!(%Organization{name: "Acme3", slug: "acme3"})

      Repo.insert!(%OrganizationMembership{
        organization_id: org.id,
        user_id: scope.user.id,
        role: :viewer
      })

      team = Repo.insert!(%Team{organization_id: org.id, name: "Ops", slug: "ops"})

      service =
        Repo.insert!(%Service{
          organization_id: org.id,
          team_id: team.id,
          name: "API",
          slug: "api",
          integration_key: "t-key"
        })

      {:ok, incident} =
        Incidents.trigger_incident_by_integration_key(%{
          "integration_key" => service.integration_key,
          "title" => "Test"
        })

      assert {:error, :forbidden} = Incidents.acknowledge_incident(scope, org.id, incident.id)

      # upgrade membership
      _ =
        Repo.delete_all(
          from(m in OrganizationMembership,
            where: m.organization_id == ^org.id and m.user_id == ^scope.user.id
          )
        )

      Repo.insert!(%OrganizationMembership{
        organization_id: org.id,
        user_id: scope.user.id,
        role: :responder
      })

      assert {:ok, _} = Incidents.acknowledge_incident(scope, org.id, incident.id)
      assert {:ok, _} = Incidents.resolve_incident(scope, org.id, incident.id)
    end

    test "org-scoped incident fetch enforces membership" do
      scope = user_scope_fixture()

      org = Repo.insert!(%Organization{name: "Acme4", slug: "acme4"})
      team = Repo.insert!(%Team{organization_id: org.id, name: "Ops", slug: "ops"})

      service =
        Repo.insert!(%Service{
          organization_id: org.id,
          team_id: team.id,
          name: "API",
          slug: "api",
          integration_key: "fetch-key"
        })

      {:ok, incident} =
        Incidents.trigger_incident_by_integration_key(%{
          "integration_key" => service.integration_key,
          "title" => "Test"
        })

      assert_raise Ecto.NoResultsError, fn ->
        Incidents.get_incident_for_user!(scope, org.id, incident.id)
      end

      Repo.insert!(%OrganizationMembership{
        organization_id: org.id,
        user_id: scope.user.id,
        role: :viewer
      })

      assert %{} = Incidents.get_incident_for_user!(scope, org.id, incident.id)
    end
  end
end
