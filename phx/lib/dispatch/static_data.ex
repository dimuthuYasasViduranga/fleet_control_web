defmodule Dispatch.StaticData do
  @moduledoc nil

  alias Dispatch.{
    AssetAgent,
    OperatorAgent,
    LocationAgent,
    TimeCodeAgent,
    CalendarAgent,
    OperatorMessageTypeAgent,
    LoadStyleAgent,
    MapTileAgent,
    MaterialTypeAgent
  }

  @spec fetch() :: map
  def fetch() do
    clusters = ClusterGraph.Agent.get() |> elem(0)

    locations =
      LocationAgent.active_locations()
      |> Enum.map(&Map.drop(&1, [:polygon]))

    %{
      timezone: CalendarAgent.timezone(),
      map_config: %{
        key: Application.get_env(:dispatch_web, :g_map_key),
        center: Application.get_env(:dispatch_web, :map_center),
        manifest: MapTileAgent.get()
      },
      assets: AssetAgent.get_assets(),
      asset_types: AssetAgent.get_types(),
      operators: OperatorAgent.all(),
      locations: locations,
      clusters: clusters,
      shifts: CalendarAgent.shifts(),
      shift_types: CalendarAgent.shift_types(),
      time_codes: TimeCodeAgent.get_time_codes(),
      time_code_groups: TimeCodeAgent.get_time_code_groups(),
      time_code_categories: TimeCodeAgent.get_time_code_categories(),
      operator_message_types: OperatorMessageTypeAgent.types(),
      load_styles: LoadStyleAgent.all(),
      material_types: MaterialTypeAgent.get()
    }
  end
end
