defmodule FleetControlWeb.DispatcherChannel.Setup do
  alias FleetControl.EngineHoursAgent
  alias FleetControl.DispatcherMessageAgent
  alias FleetControl.DigUnitActivityAgent
  alias FleetControl.DeviceAuthServer
  alias FleetControlWeb.Settings
  alias FleetControl.TimeCodeAgent
  alias FleetControl.OperatorAgent
  alias FleetControl.DispatcherAgent
  alias FleetControl.OperatorMessageTypeAgent
  alias FleetControl.HaulTruckDispatchAgent
  alias FleetControl.TrackAgent
  alias FleetControl.AssetRadioAgent
  alias FleetControl.LiveQueueAgent
  alias FleetControl.DeviceConnectionAgent
  alias FleetControl.DeviceAssignmentAgent
  alias FleetControl.TimeAllocation
  alias FleetControl.DeviceAgent
  alias FleetControl.ActivityAgent
  alias FleetControl.RoutingAgent
  alias FleetControl.OperatorMessageAgent
  alias FleetControl.PreStartAgent
  alias FleetControl.PreStartSubmissionAgent

  def join(permissions) do
    {devices, accept_until} = DeviceAuthServer.get()

    pending_devices = %{
      devices: devices,
      accept_until: accept_until
    }

    %{
      permissions: permissions,
      settings: Settings.get(),
      # constants
      time_code_tree_elements: TimeCodeAgent.get_time_code_tree_elements(),
      operator_message_type_tree: OperatorMessageTypeAgent.tree_elements(),
      operators: OperatorAgent.all(),
      dispatchers: DispatcherAgent.all(),
      pre_start_ticket_status_types: PreStartSubmissionAgent.ticket_status_types(),
      pre_start_control_categories: PreStartAgent.categories(),
      routing: RoutingAgent.get(),

      # devices
      devices: DeviceAgent.safe_all(),
      device_assignments: %{
        current: DeviceAssignmentAgent.current(),
        historic: DeviceAssignmentAgent.historic()
      },
      pending_devices: pending_devices,
      device_connections: DeviceConnectionAgent.get(),

      # common
      live_queue: LiveQueueAgent.get(),
      activities: ActivityAgent.get(),
      operator_messages: OperatorMessageAgent.all(),
      dispatcher_messages: DispatcherMessageAgent.all(),
      engine_hours: %{
        current: EngineHoursAgent.current(),
        historic: EngineHoursAgent.historic()
      },
      radio_numbers: AssetRadioAgent.all(),
      time_allocations: %{
        active: TimeAllocation.Agent.active(),
        historic: TimeAllocation.Agent.historic()
      },
      pre_start_forms: PreStartAgent.all(),
      current_pre_start_submissions: PreStartSubmissionAgent.current(),
      tracks: TrackAgent.all(),

      # haul truck
      haul_truck: %{
        dispatches: %{
          current: HaulTruckDispatchAgent.current(),
          historic: HaulTruckDispatchAgent.historic()
        }
      },

      # dig unit
      dig_unit: %{
        activities: %{
          current: DigUnitActivityAgent.current(),
          historic: DigUnitActivityAgent.historic(),
          live: DigUnitActivityAgent.fetch_dig_unit_activities(nil, nil)
        }
      }
    }
  end
end
