defmodule DispatchWeb.Application do
  @moduledoc false

  use Application

  def agents() do
    [
      # agents
      Dispatch.LocationAgent,
      Dispatch.CalendarAgent,
      Dispatch.AssetAgent,
      Dispatch.DeviceAgent,
      Dispatch.DispatcherAgent,
      Dispatch.OperatorAgent,
      Dispatch.TimeCodeAgent,
      Dispatch.DeviceAssignmentAgent,
      Dispatch.OperatorMessageTypeAgent,
      Dispatch.OperatorMessageAgent,
      Dispatch.DispatcherMessageAgent,
      Dispatch.ActivityAgent,
      Dispatch.HaulTruckDispatchAgent,
      Dispatch.DigUnitActivityAgent,
      Dispatch.EngineHoursAgent,
      Dispatch.AssetRadioAgent,
      Dispatch.LoadStyleAgent,
      Dispatch.MapTileAgent,
      Dispatch.FleetOpsAgent,
      Dispatch.ManualCycleAgent,
      Dispatch.MaterialTypeAgent,
      Dispatch.PreStartAgent,
      Dispatch.PreStartSubmissionAgent,

      # agents that call other agents
      Dispatch.TimeAllocationAgent,

      # track subscriber
      Dispatch.TrackAgent,
      Dispatch.TrackSub,

      # authorization server
      Dispatch.DeviceAuthServer
    ]
  end

  def start(_type, _args) do
    children =
      [
        [
          # repo
          HpsData.Repo,
          HpsData.Encryption.Vault
        ],
        agents(),
        [
          {Phoenix.PubSub, [name: DispatchWeb.PubSub, adapter: Phoenix.PubSub.PG2]},
          DispatchWeb.Endpoint,
          DispatchWeb.Presence
        ]
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: DispatchWeb.Supervisor]
    return = Supervisor.start_link(children, opts)

    :ok = DispatchWeb.Timers.start()

    return
  end

  def config_change(changed, _new, removed) do
    DispatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
