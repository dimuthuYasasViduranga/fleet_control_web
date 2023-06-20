defmodule FleetControlWeb.HaulController do
  @moduledoc nil

  use FleetControlWeb, :controller

  def recent(conn, _) do
    data =
      fn -> FleetControl.Haul.recent() end
      |> Task.async()
      |> Task.await()

    json(conn, data)
  end
end
