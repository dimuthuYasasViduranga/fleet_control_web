defmodule Dispatch.AgentHelperTest do
  use ExUnit.Case
  @moduletag :unit

  alias Dispatch.AgentHelper

  defp start(data), do: AgentHelper.start_link(fn -> data end)

  defp agent_get(), do: Agent.get(__MODULE__, & &1)
  defp agent_get(key), do: Agent.get(__MODULE__, & &1[key])

  describe "set -" do
    test "set entire agent" do
      start([])
      expected = "apple"
      :ok = AgentHelper.set(__MODULE__, expected)
      assert agent_get() == expected
    end

    test "set entire agent with function" do
      start([])
      expected = "apple"
      :ok = AgentHelper.set(__MODULE__, fn -> expected end)
      assert agent_get() == expected
    end

    test "set agent key" do
      key = :name
      start(%{key => []})
      expected = "apple"
      :ok = AgentHelper.set(__MODULE__, key, expected)
      assert agent_get(key) == expected
    end

    test "set agent key with function" do
      key = :name
      start(%{key => []})
      expected = "apple"
      :ok = AgentHelper.set(__MODULE__, key, fn -> expected end)
      assert agent_get(key) == expected
    end
  end
end
