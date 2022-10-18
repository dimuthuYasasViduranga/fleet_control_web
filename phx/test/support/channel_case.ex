defmodule FleetControlWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  @agents_not_started [Dispatch.MapTileAgent]

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import Bureaucrat.Helpers
      import FleetControlWeb.ChannelCase

      # The default endpoint for testing
      @endpoint FleetControlWeb.Endpoint
    end
  end

  setup_all _ do
    start_supervised!(
      {Phoenix.PubSub, [name: FleetControlWeb.PubSub, adapter: Phoenix.PubSub.PG2]}
    )

    start_supervised!(FleetControlWeb.Endpoint, [])
    start_supervised!(FleetControlWeb.Presence, [])

    start_supervised!(HpsData.Repo, [])
    start_supervised!(HpsData.Encryption.Vault, [])
    :ok
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HpsData.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HpsData.Repo, {:shared, self()})
    end

    start_agents()
    start_supervised!({FleetControlWeb.ChannelWatcher, :operators}, [])

    :ok
  end

  defp start_agents() do
    FleetControlWeb.Application.agents()
    |> Enum.reject(&Enum.member?(@agents_not_started, &1))
    |> Enum.map(&start_supervised!/1)
  end

  defmacro assert_broadcast_receive(
             socket,
             event,
             payload \\ Macro.escape(%{}),
             timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout)
           ) do
    quote do
      topic =
        case unquote(socket) do
          %{topic: topic} -> topic
          topic -> topic
        end

      assert_receive %Phoenix.Socket.Message{
                       topic: ^topic,
                       event: unquote(event),
                       payload: unquote(payload)
                     },
                     unquote(timeout)
    end
  end

  defmacro refute_broadcast_receive(
             socket,
             event,
             timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout)
           ) do
    quote do
      topic =
        case unquote(socket) do
          %{topic: topic} -> topic
          topic -> topic
        end

      refute_receive %Phoenix.Socket.Message{
                       topic: ^topic,
                       event: unquote(event)
                     },
                     unquote(timeout)
    end
  end
end
