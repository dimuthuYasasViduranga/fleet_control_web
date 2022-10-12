defmodule FleetControlWeb.OperatorChannel.WaterCartTopics do
  @moduledoc """
  Holds all water cart specific topics
  """
  alias FleetControl.HaulTruckDispatchAgent

  def get_asset_type_state(_asset, _operator_id) do
    %{
      haul_truck_dispatches: HaulTruckDispatchAgent.current()
    }
  end
end
