defmodule DispatchWeb.Authorization.Permissions do
  alias DispatchWeb.Authorization.AzureGraph

  @spec default_permissions() :: map()
  def default_permissions() do
    %{
      authorized: false,
      can_dispatch: false,
      can_edit_devices: false,
      can_edit_operators: false,
      can_edit_time_allocations: false,
      can_lock_time_allocations: false,
      can_edit_time_codes: false,
      can_edit_messages: false,
      can_refresh_agents: false,
      can_edit_routing: false,
      can_edit_pre_starts: false,
      can_edit_pre_start_tickets: false,
      can_edit_asset_roster: false
    }
  end

  @spec full_permissions() :: map()
  def full_permissions() do
    default_permissions()
    |> Enum.map(fn {key, _} -> {key, true} end)
    |> Enum.into(%{})
  end

  @spec fetch_permissions(user_id :: String.t()) :: map
  def fetch_permissions(nil), do: default_permissions()

  def fetch_permissions(user_id) do
    assigned_groups = AzureGraph.group_ids(user_id)
    config = Application.get_env(:dispatch_web, :permissions, %{})

    generate_permissions(config, assigned_groups)
  end

  defp generate_permissions(config, assigned_groups) do
    default_permissions()
    |> Enum.map(fn {permission, _} ->
      {permission, is_member_of?(config[permission], assigned_groups)}
    end)
    |> Enum.into(%{})
  end

  defp is_member_of?(nil, _), do: false

  defp is_member_of?(_, nil), do: false

  defp is_member_of?(groups, targets) when is_list(targets) do
    Enum.any?(groups, &Enum.member?(targets, &1))
  end
end
