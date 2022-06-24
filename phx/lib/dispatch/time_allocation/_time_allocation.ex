defmodule Dispatch.TimeAllocation.Helper do
  @moduledoc """
  NOTE: I would prefer to call this Dispatch.TimeAllocation, but it conflicts with

  HpsData.Schemas.Dispatch.TimeAllocation
  """

  def naive_compare?(nil, eq, nil), do: Enum.member?(eq, :eq)
  def naive_compare?(nil, eq, _), do: Enum.member?(eq, :l_nil)
  def naive_compare?(_, eq, nil), do: Enum.member?(eq, :r_nil)
  def naive_compare?(a, eq, b), do: Enum.member?(eq, NaiveDateTime.compare(a, b))
end
