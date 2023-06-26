defmodule FleetControlWeb.HaulController do
  @moduledoc nil

  use FleetControlWeb, :controller

  def recent(conn, _) do
    data = FleetControl.Haul.recent()
    json(conn, data)
  end
end
