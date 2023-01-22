defmodule FleetControl.AgentHelper do
  @moduledoc """
  A helper module to help with culling data based on size and age
  """
  require Logger
  alias FleetControl.Culling

  @error_timeout 1000

  @type list_func :: (() -> list())
  @type on_start :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}

  @spec start_link(list_func) :: on_start
  def start_link(init_func) do
    {:module, caller_module} = Function.info(init_func, :module)

    try do
      init_func.()
    rescue
      error ->
        Logger.error(inspect(error))
        Logger.error(Exception.format(:error, error, __STACKTRACE__))
        Logger.warn("waiting to initialise #{caller_module}")
        :timer.sleep(@error_timeout)
        start_link(init_func)
    else
      state -> Agent.start_link(fn -> state end, [name: caller_module, hibernate_after: 60_000])
    end
  end

  @spec set(module, any | fun) :: :ok
  def set(module, value_or_func)
  def set(module, fun) when is_function(fun), do: Agent.update(module, fn _ -> fun.() end)
  def set(module, value), do: Agent.update(module, fn _ -> value end)

  @spec set(module, atom | String.t(), any | fun) :: :ok
  def set(module, key, value_or_func)

  def set(module, key, fun) when is_function(fun) do
    Agent.update(module, &Map.put(&1, key, fun.()))
  end

  def set(module, key, value), do: Agent.update(module, &Map.put(&1, key, value))

  @spec add(map, atom | String.t(), any | list, map) :: map
  def add(state, key, element_or_elements, opts) do
    list = Culling.add(state[key], element_or_elements, opts)
    Map.put(state, key, list)
  end

  @spec override_or_add(map, atom | String.t(), any, fun, map) :: map
  def override_or_add(state, key, element, fun, opts) do
    list = Culling.override_or_add(state[key], element, fun, opts)
    Map.put(state, key, list)
  end

  @spec override(map, atom | String.t(), any, fun, map) :: map
  def override(state, key, element, fun, opts) do
    list = Culling.override(state[key], element, fun, opts)
    Map.put(state, key, list)
  end
end
