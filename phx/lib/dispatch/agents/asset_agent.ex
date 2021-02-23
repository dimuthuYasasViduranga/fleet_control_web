defmodule Dispatch.AssetAgent do
  @moduledoc """
  Stores all assets and asset types. Does not update once loaded
  """
  use Agent
  require Logger
  import Ecto.Query, only: [from: 2]

  alias Dispatch.AgentHelper
  alias HpsData.{Asset, AssetType}
  alias HpsData.Repo

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      assets: pull_assets(),
      types: pull_asset_types()
    }
  end

  defp get_secondary_type(type) do
    Application.get_env(:dispatch_web, :secondary_types, %{})
    |> Map.get(type)
  end

  defp pull_assets() do
    from(a in Asset,
      left_join: at in AssetType,
      on: [id: a.asset_type_id],
      order_by: [asc: a.name],
      select: %{
        id: a.id,
        name: a.name,
        type_id: at.id,
        type: at.type
      }
    )
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :secondary_type, get_secondary_type(&1.type)))
  end

  defp pull_asset_types() do
    from(at in AssetType,
      select: %{
        id: at.id,
        type: at.type
      }
    )
    |> Repo.all()
    |> Enum.map(&Map.put(&1, :secondary, get_secondary_type(&1.type)))
  end

  defp get(key), do: Agent.get(__MODULE__, & &1[key])

  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, init())

  @spec get_assets() :: list()
  def get_assets(), do: get(:assets)

  @spec get_asset(map()) :: map()
  def get_asset(%{id: id}) do
    Enum.find(get_assets(), &(&1.id == id))
  end

  def get_asset(%{name: name}) do
    Enum.find(get_assets(), &(&1.name == name))
  end

  @spec get_assets(map()) :: list()
  def get_assets(%{type_id: type_id}) do
    Enum.filter(get_assets(), &(&1.type_id == type_id))
  end

  def get_assets(%{type: type}) do
    Enum.filter(get_assets(), &(&1.type == type))
  end

  @spec get_types() :: list()
  def get_types(), do: get(:types)

  @spec get_type(map) :: map()
  def get_type(%{id: id}) do
    Enum.find(get_types(), &(&1.id == id))
  end

  def get_type(%{type: type}) do
    Enum.find(get_types(), &(&1.type == type))
  end
end
