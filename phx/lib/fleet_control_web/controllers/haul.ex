defmodule FleetControlWeb.HaulController do
  @moduledoc nil

  use FleetControlWeb, :controller

  def recent(conn, _) do
    task = Task.async(fn -> Jason.encode!(FleetControl.Haul.recent()) end)
    data = Task.await(task)
    conn |> send_resp(200, data)
  end
end
