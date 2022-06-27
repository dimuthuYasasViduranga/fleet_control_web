defmodule FleetControlWeb.Application do
  @moduledoc false

  use Application

  defimpl Inspect, for: HTTPoison.Response do
    def inspect(response, opts) do
      %{response | headers: "--redacted--", request_url: "--redacted--", request: "--redacted--"}
      |> Inspect.Any.inspect(opts)
    end
  end

  def agents() do
    [
      # agents
      FleetControl.LocationAgent,
      FleetControl.CalendarAgent,
      FleetControl.AssetAgent,
      FleetControl.DeviceAgent,
      FleetControl.DispatcherAgent,
      FleetControl.OperatorAgent,
      FleetControl.TimeCodeAgent,
      FleetControl.DeviceAssignmentAgent,
      FleetControl.OperatorMessageTypeAgent,
      FleetControl.OperatorMessageAgent,
      FleetControl.DispatcherMessageAgent,
      FleetControl.ActivityAgent,
      FleetControl.HaulTruckDispatchAgent,
      FleetControl.DigUnitActivityAgent,
      FleetControl.EngineHoursAgent,
      FleetControl.AssetRadioAgent,
      FleetControl.LoadStyleAgent,
      FleetControl.MapTileAgent,
      FleetControl.HaulAgent,
      FleetControl.MaterialTypeAgent,
      FleetControl.PreStartAgent,
      FleetControl.PreStartSubmissionAgent,
      FleetControl.RoutingAgent,
      FleetControl.LiveQueueAgent,

      # agents that call other agents
      FleetControl.TimeAllocation.Agent,

      # track subscriber
      FleetControl.TrackAgent,

      # authorization server
      FleetControl.DeviceAuthServer,
      FleetControl.DeviceConnectionAgent
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
          {Phoenix.PubSub, [name: FleetControlWeb.PubSub, adapter: Phoenix.PubSub.PG2]},
          FleetControlWeb.Endpoint,
          FleetControlWeb.Presence,
          {FleetControlWeb.ChannelWatcher, :operators}
        ]
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: FleetControlWeb.Supervisor]
    return = Supervisor.start_link(children, opts)

    :ok = FleetControlWeb.Timers.start()

    Node.start(:"fleet-control-ui", :shortnames)

    return
  end

  def config_change(changed, _new, removed) do
    FleetControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
