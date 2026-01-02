defmodule IncidentManagementPlatform.Repo do
  use Ecto.Repo,
    otp_app: :incident_management_platform,
    adapter: Ecto.Adapters.Postgres
end
