defmodule FleetControl.MaterialTypeAgent do
  @moduledoc """
  Holds all material types (deleted or not)
  This does not update once started
  """

  alias FleetControl.AgentHelper
  use Agent

  alias HpsData.Repo
  alias HpsData.Dim.MaterialType

  @type material_type :: map

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      material_types: pull_material_types()
    }
  end

  defp pull_material_types() do
    MaterialType
    |> Repo.all()
    |> Enum.map(&MaterialType.to_map/1)
  end

  @spec get() :: list(material_type)
  def get(), do: Agent.get(__MODULE__, & &1.material_types)

  @spec get_active() :: list(material_type)
  def get_active(), do: Enum.filter(get(), &(&1.deleted != true))
end
