defmodule Dispatch.OperatorAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.OperatorAgent
  alias HpsData.Schemas.Dispatch.Operator

  setup _ do
    OperatorAgent.start_link([])
    :ok
  end

  describe "add -" do
    test "valid" do
      employee_id = "123"
      name = "Name"
      {:ok, actual} = OperatorAgent.add(employee_id, name, nil)

      # return
      assert actual.employee_id == employee_id
      assert actual.name == name
      assert actual.nickname == nil

      # store
      assert OperatorAgent.all() == [actual]

      # database
      assert_db_contains(Operator, actual)
    end

    test "invalid (invalid employee id)" do
      actual = OperatorAgent.add(nil, "Test", nil)
      assert actual == {:error, :invalid_employee_id}
    end

    test "invalid (employee id taken)" do
      employee_id = "1"
      {:ok, initial} = OperatorAgent.add(employee_id, "Test", nil)
      error = OperatorAgent.add(employee_id, "test 2", nil)

      # return
      assert error == {:error, :employee_id_taken}

      # store
      assert OperatorAgent.all() == [initial]

      # database
      assert_db_contains(Operator, initial)
    end
  end

  describe "update -" do
    test "valid" do
      {:ok, initial} = OperatorAgent.add("123", "Test", nil)

      new_name = "test 2"
      new_nickname = "apple"
      {:ok, actual} = OperatorAgent.update(initial.id, new_name, new_nickname)

      # return
      assert actual.name == new_name
      assert actual.nickname == new_nickname
      assert actual.id == initial.id

      # store
      assert OperatorAgent.all() == [actual]

      # database
      assert_db_contains(Operator, actual)
      refute_db_contains(Operator, initial)
    end

    test "invalid (id)" do
      actual = OperatorAgent.update(-1, "Name", nil)
      assert actual == {:error, :invalid_id}
    end

    test "invalid (clear name)" do
      {:ok, operator} = OperatorAgent.add("123", "Test", nil)
      error = OperatorAgent.update(operator.id, nil, nil)

      # return
      assert_ecto_error(error)

      # store
      assert OperatorAgent.all() == [operator]

      # database
      assert_db_contains(Operator, operator)
    end
  end

  describe "delete -" do
    test "valid" do
      {:ok, initial} = OperatorAgent.add("123", "Test", nil)
      {:ok, deleted} = OperatorAgent.delete(initial.id)

      # returns
      assert deleted.id == initial.id
      assert initial.deleted == false
      assert deleted.deleted == true

      # store
      assert OperatorAgent.all() == [deleted]

      # database
      assert_db_contains(Operator, deleted)
      refute_db_contains(Operator, initial)
    end

    test "invalid (id)" do
      actual = OperatorAgent.delete(-1)
      assert actual == {:error, :invalid_id}
    end

    test "invalid (already deleted)" do
      {:ok, initial} = OperatorAgent.add("123", "Test", nil)
      {:ok, deleted} = OperatorAgent.delete(initial.id)
      error = OperatorAgent.delete(initial.id)

      # return
      assert error == {:error, :already_deleted}

      # store
      assert OperatorAgent.all() == [deleted]

      # database
      assert_db_contains(Operator, deleted)
      refute_db_contains(Operator, initial)
    end
  end

  describe "restore -" do
    test "valid" do
      {:ok, initial} = OperatorAgent.add("123", "Test", nil)
      {:ok, deleted} = OperatorAgent.delete(initial.id)
      {:ok, restored} = OperatorAgent.restore(initial.id)

      # return
      assert restored.id == initial.id
      assert deleted.deleted == true
      assert restored.deleted == false

      # store
      assert OperatorAgent.all() == [restored]

      # database
      assert_db_contains(Operator, restored)
      refute_db_contains(Operator, [initial, deleted])
    end

    test "invalid (id)" do
      actual = OperatorAgent.restore(-1)
      assert actual == {:error, :invalid_id}
    end

    test "invalid (not deleted)" do
      {:ok, operator} = OperatorAgent.add("123", "Test", nil)
      error = OperatorAgent.restore(operator.id)

      # return
      assert operator.deleted == false
      assert error == {:error, :not_deleted}

      # store
      assert OperatorAgent.all() == [operator]

      # database
      assert_db_contains(Operator, operator)
    end
  end
end
