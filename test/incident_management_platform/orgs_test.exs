defmodule IncidentManagementPlatform.OrgsTest do
  use IncidentManagementPlatform.DataCase

  alias IncidentManagementPlatform.Orgs
  alias IncidentManagementPlatform.Orgs.OrganizationMembership

  import IncidentManagementPlatform.AccountsFixtures

  describe "organizations" do
    test "create_organization/2 creates org and grants admin membership" do
      scope = user_scope_fixture()

      {:ok, org} =
        Orgs.create_organization(scope, %{
          "name" => "Acme",
          "slug" => "acme"
        })

      membership =
        Repo.get_by!(OrganizationMembership,
          organization_id: org.id,
          user_id: scope.user.id
        )

      assert membership.role == :admin
    end

    test "list_organizations/1 returns only user orgs" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()

      {:ok, org1} = Orgs.create_organization(scope1, %{"name" => "Org One", "slug" => "org-one"})
      {:ok, _org2} = Orgs.create_organization(scope2, %{"name" => "Org Two", "slug" => "org-two"})

      orgs = Orgs.list_organizations(scope1)
      assert Enum.any?(orgs, &(&1.id == org1.id))
      refute Enum.any?(orgs, &(&1.slug == "org-two"))
    end
  end

  describe "teams" do
    test "create_team/3 requires admin role" do
      scope = user_scope_fixture()
      {:ok, org} = Orgs.create_organization(scope, %{"name" => "Acme", "slug" => "acme-teams"})

      # Downgrade membership to viewer
      membership =
        Repo.get_by!(OrganizationMembership, organization_id: org.id, user_id: scope.user.id)

      {:ok, _} = membership |> Ecto.Changeset.change(role: :viewer) |> Repo.update()

      assert {:error, :forbidden} =
               Orgs.create_team(scope, org.id, %{"name" => "Ops", "slug" => "ops"})
    end
  end
end
