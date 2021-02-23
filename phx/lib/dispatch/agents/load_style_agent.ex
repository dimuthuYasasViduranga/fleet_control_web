defmodule Dispatch.LoadStyleAgent do
  @moduledoc """
  Stores all load styles. Does not update once loaded
  """
  use Agent

  require Logger

  alias Dispatch.AgentHelper

  alias HpsData.{AssetType}
  alias HpsData.Repo
  alias HpsData.Schemas.Dispatch.LoadStyle

  import Ecto.Query, only: [from: 2]

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init(), do: pull_styles()

  defp pull_styles() do
    from(s in LoadStyle,
      join: at in AssetType,
      on: [id: s.asset_type_id],
      select: %{
        id: s.id,
        style: s.style,
        asset_type_id: at.id,
        asset_type: at.type
      }
    )
    |> Repo.all()
  end

  def all(), do: Agent.get(__MODULE__, & &1)

  def get_by(key, value), do: Enum.find(all(), &(&1[key] == value))

  def get(%{id: id}), do: get_by(:id, id)

  def get(%{style: style}), do: get_by(:style, style)

  def get(%{asset_type_id: id}), do: get_by(:asset_type_id, id)

  def get(%{asset_type: type}), do: get_by(:asset_type, type)
end
