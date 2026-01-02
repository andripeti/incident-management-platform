defmodule IncidentManagementPlatformWeb.PageController do
  use IncidentManagementPlatformWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
