defmodule IncidentManagementPlatformWeb.IncidentWebhookController do
  use IncidentManagementPlatformWeb, :controller

  alias IncidentManagementPlatform.Incidents

  def trigger(conn, params) do
    case Incidents.trigger_incident_by_integration_key(params) do
      {:ok, incident} ->
        json(conn, %{
          incident_id: incident.id,
          organization_id: incident.organization_id,
          service_id: incident.service_id,
          status: incident.status
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "unknown_integration_key"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "invalid_payload", details: errors_to_map(changeset)})
    end
  end

  defp errors_to_map(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
