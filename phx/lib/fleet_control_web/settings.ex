defmodule FleetControlWeb.Settings do
  @spec get() :: map()
  def get() do
    Application.get_env(:fleet_control_web, :settings, []) |> Enum.into(%{})
  end

  def get(key, default \\ nil), do: Map.get(get(), key, default)

  @spec set(atom, boolean) :: :ok
  def set(key, bool) when is_boolean(bool) do
    settings =
      Application.get_env(:fleet_control_web, :settings, [])
      |> Keyword.put(key, bool)

    Application.put_env(:fleet_control_web, :settings, settings)
  end
end
