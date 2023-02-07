defmodule FleetControlWeb.Authorization.Permissions do
  alias FleetControlWeb.Authorization.AzureGraph

  @doc """
  assigned in both socket and session
  """
  def fetch_permissions(user_id) do
    bypass_auth = Application.compile_env(:fleet_control_web, :bypass_auth, false)

    cond do
      bypass_auth -> set_permissions(true)
      is_nil(user_id) -> set_permissions(false)
      true -> do_fetch_permissions(user_id)
    end
  end

  defp do_fetch_permissions(user_id) do
    assigned_groups = AzureGraph.group_ids(user_id)
    config = Application.get_env(:fleet_control_web, :permissions, %{})

    generate_permissions(config, assigned_groups)
  end

  defp set_permissions(value) do
    %{
      authorized: value,
      can_dispatch: value,
      can_edit_devices: value,
      can_edit_operators: value,
      can_edit_time_allocations: value,
      can_lock_time_allocations: value,
      can_edit_time_codes: value,
      can_edit_messages: value,
      can_refresh_agents: value,
      can_edit_routing: value,
      can_edit_pre_starts: value,
      can_edit_pre_start_tickets: value,
      can_edit_asset_roster: value
    }
  end

  defp generate_permissions(config, assigned_groups) do
    default_permissions()
    |> Enum.map(fn {permission, _} ->
      {permission, is_member_of?(config[permission], assigned_groups)}
    end)
    |> Enum.into(%{})
  end

  defp is_member_of?(:any, _), do: true
  defp is_member_of?(nil, _), do: false
  defp is_member_of?(_, nil), do: false

  defp is_member_of?(groups, targets) when is_list(targets) do
    Enum.any?(groups, &Enum.member?(targets, &1))
  end
end
