defmodule DispatchWeb.OperatorChannel.WaterCartTopics do
  @moduledoc """
  Holds all water cart specific topics
  """
  alias Dispatch.HaulTruckDispatchAgent

  def get_asset_type_state(_asset, _operator) do
    %{
      haul_truck_dispatches: HaulTruckDispatchAgent.current()
    }
  end
end