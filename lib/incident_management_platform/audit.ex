defmodule IncidentManagementPlatform.Audit do
  @moduledoc """
  The Audit context.

  Audit logs capture all security-relevant and operational state transitions.
  This is separate from `IncidentEvents`, which is incident-scoped and optimized for
  the LiveView activity feed.

  This context is intentionally append-only.
  """

  import Ecto.Query, warn: false

  alias IncidentManagementPlatform.Audit.AuditLog
  alias IncidentManagementPlatform.Repo

  @doc "List audit logs for an organization, newest first."
  def list_audit_logs(organization_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    AuditLog
    |> where([a], a.organization_id == ^organization_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
