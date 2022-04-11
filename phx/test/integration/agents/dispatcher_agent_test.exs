defmodule Dispatch.DispatcherMessageTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.DispatcherAgent
  alias HpsData.Schemas.Dispatch.Dispatcher

  setup do
    DispatcherAgent.start_link([])
    :ok
  end

  describe "add -" do
    test "valid (no existing)" do
      user_id = "1234"
      name = "test"

      {:ok, actual} = DispatcherAgent.add(user_id, name)

      # return
      assert actual.user_id == user_id
      assert actual.name == name
      assert actual.updated_at != nil

      # store
      assert DispatcherAgent.all() == [actual]

      # database
      assert_db_contains(Dispatcher, actual)
    end

    test "valid (update name)" do
      user_id = "1234"
      name_1 = "test 1"
      name_2 = "test 2"

      {:ok, initial} = DispatcherAgent.add(user_id, name_1)
      :timer.sleep(1)
      {:ok, updated} = DispatcherAgent.add(user_id, name_2)

      # return
      assert initial.user_id == user_id
      assert initial.name == name_1

      assert updated.user_id == user_id
      assert updated.name == name_2

      assert updated.id == initial.id
      assert NaiveDateTime.compare(updated.updated_at, initial.updated_at) == :gt

      # store
      assert DispatcherAgent.all() == [updated]

      # database
      assert_db_contains(Dispatcher, updated)
      refute_db_contains(Dispatcher, initial)
    end

    test "valid (change nothing)" do
      user_id = "1234"
      name = "test"

      {:ok, initial} = DispatcherAgent.add(user_id, name)
      :timer.sleep(1)
      {:ok, updated} = DispatcherAgent.add(user_id, name)

      assert initial.user_id == user_id
      assert initial.name == name

      assert updated.user_id == user_id
      assert updated.name == name

      assert updated.id == initial.id
      assert NaiveDateTime.compare(updated.updated_at, initial.updated_at) == :gt

      # store
      assert DispatcherAgent.all() == [updated]

      # database
      assert_db_contains(Dispatcher, updated)
      refute_db_contains(Dispatcher, initial)
    end

    test "valid (empty user_id - useful for local dev)" do
      user_id = nil
      name = "dev"

      {:ok, actual} = DispatcherAgent.add(user_id, name)

      # return
      assert actual.user_id == user_id
      assert actual.name == name
      assert actual.updated_at != nil

      # store
      assert DispatcherAgent.all() == [actual]

      # database
      assert_db_contains(Dispatcher, actual)
    end

    test "invalid (duplicate user_id)" do
      user_id = "1234"
      name = "test 1"

      {:ok, initial} = DispatcherAgent.add(user_id, name)

      error =
        %{
          user_id: user_id,
          name: "test 2"
        }
        |> Dispatcher.new()
        |> Repo.insert()

      # return
      assert_ecto_error(error)
      assert initial.user_id == user_id
      assert initial.name == name

      # store
      assert DispatcherAgent.all() == [initial]

      # database
      assert_db_contains(Dispatcher, initial)
    end

    test "invalid (empty name)" do
      user_id = "1234"
      name = nil

      error = DispatcherAgent.add(user_id, name)

      assert_ecto_error(error)
    end
  end
end
