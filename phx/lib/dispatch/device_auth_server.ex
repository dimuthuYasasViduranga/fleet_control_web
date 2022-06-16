defmodule Dispatch.DeviceAuthServer do
  use GenServer
  alias DispatchWeb.Endpoint
  alias Dispatch.{Helper, DeviceAgent, Token}
  alias DispatchWeb.Broadcast.Authentication

  require Logger

  @reject_after 60

  def start_link(_opts) do
    state = %{
      accept_until: nil,
      pending_devices: []
    }

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # ------------------ info -----------------
  def handle_info({:timeout_auth_window, accept_until}, state) do
    case is_nil(state.accept_until) || state.accept_until == accept_until do
      false ->
        {:noreply, state}

      true ->
        Logger.warn("Device auth window timed out")
        state = reject_all(state)
        {:noreply, state}
    end
  end

  # # -------------------- calls ------------------
  def handle_call(:get, _from, %{pending_devices: pending, accept_until: accept_until} = state) do
    {:reply, {pending, accept_until}, state}
  end

  def handle_call(:open_auth_window, _from, state) do
    Logger.info("Opening device auth window")
    # add a timer to remove all devices

    accept_until = Helper.timestamp(:second) + @reject_after
    Process.send_after(self(), {:timeout_auth_window, accept_until}, @reject_after * 1000)

    # update the accept_until window
    state = Map.put(state, :accept_until, accept_until)

    {:reply, accept_until, state}
  end

  def handle_call(:close_auth_window, _from, state) do
    Logger.warn("Closing device auth window")

    state =
      state
      |> reject_all()
      |> Map.put(:accept_until, nil)

    {:reply, :ok, state}
  end

  def handle_call({:request_device_auth, uuid, details}, _, %{pending_devices: pending} = state) do
    case can_accept?(state) do
      false ->
        Logger.warn("Window closed - ignored device '#{uuid}'")
        {:reply, :closed, state}

      true ->
        Logger.info("Auth requested for '#{uuid}'")

        pending_devices =
          case Enum.find(pending, &(&1.uuid == uuid)) do
            nil -> pending
            _ -> Enum.reject(pending, &(&1.uuid == uuid))
          end
          |> List.insert_at(0, %{uuid: uuid, details: details || %{}})

        Authentication.send_pending_devices(pending_devices, state.accept_until)

        updated_state = Map.put(state, :pending_devices, pending_devices)
        {:reply, :ok, updated_state}
    end
  end

  def handle_call({:accept, uuid}, _from, state) do
    case can_accept?(state) do
      false ->
        Logger.info("Cannot accept, window closed: #{uuid}")
        state = Map.put(state, :pending_devices, [])
        {:reply, {:error, :window_closed}, state}

      true ->
        case Enum.find(state.pending_devices, &(&1.uuid == uuid)) do
          nil ->
            Logger.warn("[DeviceAuth] Cannot accept `#{uuid}` as it is not pending")
            {:reply, {:error, :no_device}, state}

          device ->
            # create a device token
            Logger.info("Device accepted: #{uuid}")

            {:ok, token, claims} = Token.generate_token(device.uuid)

            device_id = add_device(device)[:id]

            case DeviceAgent.update_nbf(device_id, claims) do
              {:ok, device} ->
                # remove device from pending list
                pending_devices = Enum.reject(state.pending_devices, &(&1.uuid == device.uuid))
                state = Map.put(state, :pending_devices, pending_devices)

                {:reply, {:ok, token}, state}

              {:error, reason} ->
                {:reply, {:error, reason}, state}
            end
        end
    end
  end

  def handle_call({:reject, uuid}, _from, state) do
    Logger.warn("Device rejected: #{uuid}")

    # broadcast rejection id
    reject(uuid)

    pending_devices = Enum.reject(state.pending_devices, &(&1.uuid == uuid))
    state = Map.put(state, :pending_devices, pending_devices)

    {:reply, :ok, state}
  end

  def handle_call(:reject_all, _from, state) do
    Logger.warn("All devices rejected")
    state = Map.put(state, :pending_devices, [])
    {:reply, :ok, state}
  end

  # # ---------------- helpers ---------------
  defp can_accept?(%{accept_until: nil}), do: false

  defp can_accept?(%{accept_until: accept_until}), do: Helper.timestamp(:second) < accept_until

  defp reject(uuid) do
    Endpoint.broadcast("device_auth:#{uuid}", "rejected", %{})
    Endpoint.broadcast("device_auth:#{uuid}", "disconnect", %{})
  end

  defp reject_all(state) do
    Enum.each(state.pending_devices, &reject(&1.uuid))
    Authentication.send_pending_devices([], state.accept_until)
    Map.put(state, :pending_devices, [])
  end

  defp add_device(%{uuid: uuid, details: details}) do
    case DeviceAgent.add(uuid, details) do
      {:ok, :new, new_device} ->
        Logger.warn("Added new device: #{uuid}")
        new_device

      {:ok, :exists, existing_device} ->
        Logger.warn("Device already exists: #{uuid}")
        existing_device

      _ ->
        nil
    end
  end

  # ------------------- client side ---------------
  @spec get() :: {list(map), integer | nil}
  def get(), do: GenServer.call(__MODULE__, :get)

  @spec request_device_authorization(String.t(), map) :: :ok | :closed
  def request_device_authorization(uuid, details) do
    GenServer.call(__MODULE__, {:request_device_auth, uuid, details})
  end

  def accept_device(uuid) do
    GenServer.call(__MODULE__, {:accept, uuid})
  end

  def reject_device(uuid) do
    GenServer.call(__MODULE__, {:reject, uuid})
  end

  def reject_all() do
    GenServer.call(__MODULE__, :reject_all)
  end

  def open_auth_window() do
    GenServer.call(__MODULE__, :open_auth_window)
  end

  def close_auth_window() do
    GenServer.call(__MODULE__, :close_auth_window)
  end
end
