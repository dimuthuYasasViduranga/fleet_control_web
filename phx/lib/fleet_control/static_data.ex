defmodule FleetControl.StaticData do
  @moduledoc nil

  alias FleetControl.{
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
    locations =
      LocationAgent.active_locations()
      |> Enum.map(&Map.drop(&1, [:polygon]))

    %{
      timezone: CalendarAgent.timezone(),
      quick_messages: get_quick_messages(),
      map_config: %{
        key: Application.get_env(:fleet_control_web, :g_map_key),
        center: Application.get_env(:fleet_control_web, :map_center),
        manifest: MapTileAgent.get()
      },
      assets: AssetAgent.get_assets(),
      asset_types: AssetAgent.get_types(),
      operators: OperatorAgent.all(),
      dim_locations: LocationAgent.dim_locations(),
      locations: locations,
      shifts: CalendarAgent.shifts(),
      shift_types: CalendarAgent.shift_types(),
      time_codes: TimeCodeAgent.get_time_codes(),
      time_code_groups: TimeCodeAgent.get_time_code_groups(),
      time_code_categories: TimeCodeAgent.get_time_code_categories(),
      operator_message_types: OperatorMessageTypeAgent.types(),
      load_styles: LoadStyleAgent.all(),
      material_types: MaterialTypeAgent.get(),
      location_assignment_layout: get_location_assignment_layout()
    }
  end

  defp get_location_assignment_layout() do
    Application.get_env(:fleet_control_web, :location_assignment_layout)
    |> Map.new()
  end

  defp get_quick_messages() do
    Application.get_env(:fleet_control_web, :quick_messages, [])
    |> Enum.map(&parse_quick_message/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_quick_message(message) when is_list(message) do
    case message do
      [message, a, b] ->
        message =
          case String.contains?(message, "?") do
            true -> message
            _ -> "#{message}?"
          end

        %{message: message, answers: [a, b]}

      [message] ->
        %{message: message}

      _ ->
        nil
    end
  end

  defp parse_quick_message(message) when is_binary(message), do: %{message: message}
end
