defmodule FleetControl.AssetAgent do
  @moduledoc """
  Stores all assets and asset types. Does not update once loaded
  """
  use Agent
  import Ecto.Query, only: [from: 2]

  alias FleetControl.{AgentHelper, Helper}
  alias HpsData.{Asset, AssetType}
  alias HpsData.Repo

  @type asset :: %{
          id: integer,
          name: String.t(),
          type_id: integer | nil,
          type: String.t() | nil,
          enabled: boolean
        }

  @type type :: %{
          id: integer,
          type: String.t()
        }

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    %{
      assets: pull_assets(),
      types: pull_asset_types()
    }
  end

  defp get_secondary_type(type) do
    Application.get_env(:fleet_control_web, :secondary_types, %{})
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
        type: at.type,
        enabled: a.fleet_control_enabled
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

  @spec get_asset(map()) :: asset
  def get_asset(%{id: id}) do
    Enum.find(get_assets(), &(&1.id == id))
  end

  def get_asset(%{name: name}) do
    Enum.find(get_assets(), &(&1.name == name))
  end

  @spec get_assets(map()) :: list(asset)
  def get_assets(%{type_id: type_id}) do
    Enum.filter(get_assets(), &(&1.type_id == type_id))
  end

  def get_assets(%{type: type}) do
    Enum.filter(get_assets(), &(&1.type == type))
  end

  @spec get_types() :: list(type)
  def get_types(), do: get(:types)

  @spec get_type(map) :: type
  def get_type(%{id: id}) do
    Enum.find(get_types(), &(&1.id == id))
  end

  def get_type(%{type: type}) do
    Enum.find(get_types(), &(&1.type == type))
  end

  @spec set_enabled(integer, boolean) ::
          :ok | {:error, :invalid_asset | :already_set | term}
  def set_enabled(asset_id, bool) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Helper.get_by_or_nil(Repo, Asset, %{id: asset_id}) do
        nil ->
          {{:error, :invalid_asset}, state}

        %{enabled: ^bool} ->
          {{:error, :already_set}, state}

        asset ->
          asset
          |> Asset.changeset(%{fleet_control_enabled: bool})
          |> Repo.update()

          state = Map.put(state, :assets, pull_assets())
          {:ok, state}
      end
    end)
  end
end
