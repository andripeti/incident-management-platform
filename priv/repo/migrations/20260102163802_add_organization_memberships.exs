defmodule IncidentManagementPlatform.Repo.Migrations.AddOrganizationMemberships do
  use Ecto.Migration

  def change do
    create table(:organization_memberships) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      add :role, :string, null: false, default: "viewer"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_memberships, [:organization_id, :user_id])
    create index(:organization_memberships, [:user_id])

    create constraint(:organization_memberships, :org_memberships_role_valid,
             check: "role in ('admin','responder','viewer')"
           )
  end
end
