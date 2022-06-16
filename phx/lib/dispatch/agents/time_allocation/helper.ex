defmodule Dispatch.TimeAllocationAgent.Helper do
  @moduledoc """
  NOTE: I would prefer to call this Dispatch.TimeAllocation, but it conflicts with

  HpsData.Schemas.Dispatch.TimeAllocation
  """
  @spec has_keys?(map, list(atom | String.t())) :: boolean()
  def has_keys?(map, keys), do: Enum.all?(keys, &Map.has_key?(map, &1))

  @spec naive_compare?(NaiveDateTime.t() | nil, list(atom), NaiveDateTime.t() | nil) :: boolean()
  def naive_compare?(nil, eq, nil), do: Enum.member?(eq, :eq)
  def naive_compare?(nil, eq, _), do: Enum.member?(eq, :l_nil)
  def naive_compare?(_, eq, nil), do: Enum.member?(eq, :r_nil)
  def naive_compare?(a, eq, b), do: Enum.member?(eq, NaiveDateTime.compare(a, b))
end
