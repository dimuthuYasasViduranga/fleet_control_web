defmodule Dispatch.CalendarAgent do
  @moduledoc """
  Used to store all calendar information
  """

  use Agent
  require Logger
  import Ecto.Query, only: [from: 2]

  alias Dispatch.AgentHelper
  alias HpsData.Dim.{Calendar, ShiftType, Timezone}
  alias HpsData.Repo

  @type shift :: map()
  @type shift_type :: map()
  @type range :: %{start_time: NaiveDateTime.t(), end_time: NaiveDateTime.t()}

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      shifts: pull_shifts(),
      shift_types: pull_shift_types(),
      timezone: pull_timezone()
    }
  end

  defp pull_shifts() do
    from(c in Calendar,
      order_by: c.shift_start_utc,
      select: %{
        id: c.id,
        shift_start: c.shift_start_utc,
        shift_end: c.shift_end_utc,
        site_year: c.year,
        site_month: c.month,
        site_day: c.day_of_month,
        shift_type_id: c.shift_type_id
      }
    )
    |> Repo.all()
  end

  defp pull_shift_types() do
    from(st in ShiftType,
      select: %{
        id: st.id,
        name: st.shift_name
      }
    )
    |> Repo.all()
  end

  defp pull_timezone() do
    Timezone
    |> Repo.all()
    |> List.last()
    |> Map.get(:tz)
  end

  @spec get_current() :: shift | nil
  def get_current(), do: get_at(NaiveDateTime.utc_now())

  @spec get_at(NaiveDateTime.t()) :: shift | nil
  def get_at(nil), do: nil

  def get_at(timestamp) do
    Enum.find(shifts(), &between?(&1, timestamp))
  end

  @spec get(%{asset_id: integer}) :: shift | nil
  def get(%{id: id}), do: Enum.find(shifts(), &(&1.id == id))

  @spec timezone() :: String.t()
  def timezone(), do: Agent.get(__MODULE__, & &1.timezone)

  @spec shifts() :: list(shift)
  def shifts(), do: Agent.get(__MODULE__, & &1.shifts)

  @spec shift_types() :: list(shift_type)
  def shift_types(), do: Agent.get(__MODULE__, & &1.shift_types)

  @spec between?(range, NaiveDateTime.t()) :: boolean
  def between?(%{shift_start: start_time, shift_end: end_time}, timestamp) do
    NaiveDateTime.compare(start_time, timestamp) != :gt &&
      NaiveDateTime.compare(timestamp, end_time) == :lt
  end

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, init())
end
