defmodule IncidentManagementPlatform.Audit.AuditLog do
  @moduledoc """
  Organization-scoped audit log record.

  This table is the system-of-record for state changes (who/what/when).
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :integer

    field :actor_type, :string
    field :actor_id, :integer

    field :metadata, :map

    belongs_to :organization, IncidentManagementPlatform.Orgs.Organization

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [
      :organization_id,
      :action,
      :resource_type,
      :resource_id,
      :actor_type,
      :actor_id,
      :metadata
    ])
    |> validate_required([:organization_id, :action, :resource_type, :resource_id])
    |> validate_length(:action, min: 2, max: 80)
    |> foreign_key_constraint(:organization_id)
  end
end
