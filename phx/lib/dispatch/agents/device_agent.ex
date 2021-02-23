defmodule Dispatch.DeviceAgent do
  @moduledoc """
  Used to hold all device token nbfs
  """
  use Agent

  alias Dispatch.{Helper, AgentHelper}
  alias HpsData.Schemas.Dispatch.Device
  alias HpsData.Repo

  import Ecto.Query, only: [from: 2]

  @type device :: map

  def start_link(_opts), do: AgentHelper.start_link(&init/0)

  defp init(), do: pull_devices()

  defp pull_devices() do
    from(d in Device,
      select: %{
        id: d.id,
        uuid: d.uuid,
        not_before: d.not_before,
        details: d.details
      }
    )
    |> Repo.all()
  end

  # ------------------ client calls -----------------
  @spec refresh!() :: :ok
  def refresh!(), do: AgentHelper.set(__MODULE__, &init/0)

  @spec all() :: list()
  def all(), do: Agent.get(__MODULE__, & &1)

  @spec safe_all() :: list()
  def safe_all() do
    Enum.map(all(), fn device ->
      device
      |> Map.put(:authorized, !is_nil(device.not_before))
      |> Map.drop([:not_before])
    end)
  end

  @spec get(map) :: device | nil
  def get(%{id: device_id}), do: Enum.find(all(), &(&1.id == device_id))

  def get(%{uuid: uuid}), do: Enum.find(all(), &(&1.uuid == uuid))

  @spec add(String.t(), map | nil) :: {:ok, :new | :exists, device} | {:error | term}
  def add(uuid, details \\ %{})
  def add(nil, _), do: {:error, :invalid_uuid}

  def add(uuid, details) do
    Agent.get_and_update(__MODULE__, &add_device(&1, uuid, details))
  end

  def add_device(devices, uuid, details) do
    case Repo.get_by(Device, %{uuid: uuid}) do
      nil ->
        %{uuid: uuid, details: details}
        |> Device.new()
        |> Repo.insert()
        |> update_devices(devices)
        |> case do
          {:error, error} -> {error, devices}
          {device, devices} -> {{:ok, :new, device}, devices}
        end

      device ->
        details = merge_details(device.details, details)

        device
        |> Device.changeset(%{details: details})
        |> Repo.update()
        |> update_devices(devices)
        |> case do
          {:error, error} -> {error, devices}
          {device, devices} -> {{:ok, :exists, device}, devices}
        end
    end
  end

  @spec update_details(integer, map) ::
          {:ok, device} | {:error, :invalid_id | :invalid_details | term}
  def update_details(nil, _), do: {:error, :invalid_id}

  def update_details(device_id, details) when is_map(details) do
    Agent.get_and_update(__MODULE__, &update_details(&1, device_id, details))
  end

  def update_details(_, _), do: {:error, :invalid_details}

  def update_details(devices, device_id, details) do
    case Helper.get_by_or_nil(Repo, Device, %{id: device_id}) do
      nil ->
        {{:error, :invalid_id}, devices}

      device ->
        device
        |> Device.changeset(%{details: details})
        |> Repo.update()
        |> update_devices(devices)
        |> case do
          {:error, error} -> {error, devices}
          {device, devices} -> {{:ok, device}, devices}
        end
    end
  end

  @spec revoke(integer) :: {:ok, map} | {:error, :invalid_device_id}
  def revoke(device_id), do: set_device_nbf(device_id, nil)

  @spec update_nbf(integer, map) :: {:ok, device} | {:error, :invalid_nbf | :missing_nbf | term}
  def update_nbf(_, %{"nbf" => nil}), do: {:error, :invalid_nbf}

  def update_nbf(device_id, %{"nbf" => new_nbf}), do: set_device_nbf(device_id, new_nbf)

  def update_nbf(_, _), do: {:error, :missing_nbf}

  @doc """
  A token has a valid nbf if the token has been issued (iat) since the not before time (nbf).
  """
  @spec valid_nbf?(String.t(), integer, integer) :: bool
  def valid_nbf?(device_uuid, nbf, iat) do
    device = get(%{uuid: device_uuid})

    cond do
      is_nil(device) -> false
      is_nil(nbf) -> false
      is_nil(iat) -> false
      true -> device.not_before == nbf && iat >= nbf
    end
  end

  defp set_device_nbf(device_id, nbf) do
    Agent.get_and_update(__MODULE__, &set_device_nbf(&1, device_id, nbf))
  end

  defp set_device_nbf(devices, device_id, nbf) do
    Helper.get_by_or_nil(Repo, Device, %{id: device_id})
    |> case do
      nil ->
        {{:error, :invalid_device_id}, devices}

      device ->
        device
        |> Device.changeset(%{not_before: nbf})
        |> Repo.update()
        |> update_devices(devices)
        |> case do
          {:error, error} -> {error, devices}
          {device, devices} -> {{:ok, device}, devices}
        end
    end
  end

  defp merge_details(existing, new) do
    Map.merge(new, existing, fn _, new_val, existing_val -> new_val || existing_val end)
  end

  defp update_devices({:ok, %Device{} = device}, devices) do
    device = Device.to_map(device)
    update_devices({:ok, device}, devices)
  end

  defp update_devices({:ok, device}, devices) do
    other_devices = Enum.reject(devices, &(&1.id == device.id))
    devices = [device | other_devices]
    {device, devices}
  end

  defp update_devices(error, _devices), do: {:error, error}
end
