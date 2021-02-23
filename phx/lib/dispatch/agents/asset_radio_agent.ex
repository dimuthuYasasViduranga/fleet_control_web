defmodule Dispatch.AssetRadioAgent do
  @moduledoc """
  Store for all asset radio settings
  """

  use Agent
  require Logger

  alias Dispatch.AgentHelper
  alias HpsData.Schemas.Dispatch.AssetRadio
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init() do
    from(r in AssetRadio,
      select: %{
        id: r.id,
        asset_id: r.asset_id,
        radio_number: r.radio_number
      }
    )
    |> Repo.all()
    |> Enum.map(&{&1.asset_id, &1})
    |> Enum.into(%{})
  end

  @spec all() :: list()
  def all(), do: Agent.get(__MODULE__, &Map.values(&1))

  @spec get(integer) :: map() | nil
  def get(asset_id), do: Agent.get(__MODULE__, & &1[asset_id])

  @spec set(integer, String.t() | nil) :: {:ok, map} | {:error, term}
  def set(nil, _radio_number), do: {:error, :invalid_asset_id}

  def set(asset_id, radio_number) do
    Agent.get_and_update(__MODULE__, &set_asset(&1, asset_id, radio_number))
  end

  defp set_asset(assets, asset_id, radio_number) do
    Repo.get_by(AssetRadio, asset_id: asset_id)
    |> case do
      nil ->
        %{asset_id: asset_id, radio_number: radio_number}
        |> AssetRadio.new()
        |> Repo.insert()

      record ->
        record
        |> AssetRadio.changeset(%{radio_number: radio_number})
        |> Repo.update()
    end
    |> case do
      {:ok, record} ->
        record = AssetRadio.to_map(record)
        assets = Map.put(assets, record.asset_id, record)
        {{:ok, record}, assets}

      error ->
        {error, assets}
    end
  end
end
