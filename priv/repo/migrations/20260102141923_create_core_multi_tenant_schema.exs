defmodule IncidentManagementPlatform.Repo.Migrations.CreateCoreMultiTenantSchema do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])

    create table(:teams) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:organization_id])
    create unique_index(:teams, [:organization_id, :slug])

    create table(:services) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false

      add :name, :string, null: false
      add :slug, :string, null: false
      add :integration_key, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:services, [:organization_id])
    create index(:services, [:team_id])
    create unique_index(:services, [:organization_id, :slug])
    create unique_index(:services, [:integration_key])

    create table(:incidents) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :service_id, references(:services, on_delete: :delete_all), null: false

      add :title, :string, null: false
      add :description, :text

      add :status, :string, null: false, default: "triggered"

      add :dedup_key, :string

      add :triggered_at, :utc_datetime
      add :acknowledged_at, :utc_datetime
      add :resolved_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:incidents, [:organization_id])
    create index(:incidents, [:service_id])
    create index(:incidents, [:organization_id, :status])

    create constraint(:incidents, :incidents_status_valid,
             check: "status in ('triggered','acknowledged','resolved')"
           )

    create table(:incident_events) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :incident_id, references(:incidents, on_delete: :delete_all), null: false

      add :action, :string, null: false
      add :message, :text
      add :metadata, :map

      add :actor_type, :string
      add :actor_id, :integer

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:incident_events, [:organization_id])
    create index(:incident_events, [:incident_id])
    create index(:incident_events, [:incident_id, :inserted_at])

    create table(:audit_logs) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      add :action, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :integer, null: false

      add :actor_type, :string
      add :actor_id, :integer

      add :metadata, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_logs, [:organization_id])
    create index(:audit_logs, [:organization_id, :inserted_at])
  end
end
