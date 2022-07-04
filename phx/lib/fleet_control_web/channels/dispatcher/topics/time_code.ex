defmodule FleetControlWeb.DispatcherChannel.Topics.TimeCode do
  alias FleetControl.TimeCodeAgent
  alias FleetControlWeb.Broadcast

  import FleetControlWeb.DispatcherChannel, only: [to_error: 1]

  def handle_in("time-code:set-tree-elements", payload, socket) do
    %{
      "asset_type_id" => asset_type_id,
      "elements" => elements
    } = payload

    case TimeCodeAgent.set_time_code_tree_elements(asset_type_id, elements) do
      {:error, reason} ->
        {:reply, to_error(reason), socket}

      {:ok, _inserted} ->
        Broadcast.send_time_code_tree_elements_to(%{id: asset_type_id})
        {:reply, :ok, socket}
    end
  end

  def handle_in("time-code:update", payload, socket) do
    case TimeCodeAgent.add_or_update_time_code(payload) do
      {:ok, _} ->
        Broadcast.send_time_code_data_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in("time-code:update-group", %{"id" => id, "alias" => alias_name}, socket) do
    case TimeCodeAgent.update_group(id, alias_name) do
      {:ok, _} ->
        Broadcast.send_time_code_data_to_all()
        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end

  def handle_in("time-code:bulk-add", %{"time_codes" => time_codes}, socket) do
    time_codes =
      Enum.map(time_codes, fn tc ->
        %{
          name: tc["name"],
          code: tc["code"],
          group_id: tc["group_id"],
          category_id: tc["category_id"]
        }
      end)

    case TimeCodeAgent.bulk_add_time_codes(time_codes) do
      {:ok, _time_codes} ->
        Broadcast.send_time_code_data_to_all()

        {:reply, :ok, socket}

      error ->
        {:reply, to_error(error), socket}
    end
  end
end
