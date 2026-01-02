defmodule IncidentManagementPlatformWeb.PageController do
  use IncidentManagementPlatformWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      redirect(conn, to: ~p"/orgs")
    else
      render(conn, :home)
    end
  end
end
