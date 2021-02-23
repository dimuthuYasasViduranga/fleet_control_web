defmodule Dispatch.DispatcherMessageAgentTest do
  use DispatchWeb.RepoCase
  @moduletag :agent

  alias Dispatch.{AssetAgent, DispatcherMessageAgent}
  alias HpsData.Schemas.Dispatch.Message

  defp to_message(asset_id, message, answers, timestamp \\ NaiveDateTime.utc_now()) do
    %{
      asset_id: asset_id,
      message: message,
      answers: answers,
      timestamp: timestamp
    }
  end

  setup_all _ do
    AssetAgent.start_link([])
    [asset | _] = AssetAgent.get_assets(%{type: "Haul Truck"})
    [asset: asset]
  end

  setup _ do
    DispatcherMessageAgent.start_link([])
    :ok
  end

  describe "single recipient -" do
    test "new message", %{asset: asset} do
      message = to_message(asset.id, "test message", nil)
      {:ok, actual} = DispatcherMessageAgent.new(message)

      expected = %{
        id: actual.id,
        dispatcher_id: nil,
        acknowledge_id: nil,
        answer: nil,
        answers: nil,
        asset_id: asset.id,
        group_id: nil,
        message: message.message,
        timestamp: message.timestamp,
        server_timestamp: actual.server_timestamp
      }

      # return
      assert actual == expected

      # store
      assert DispatcherMessageAgent.all() == [actual]

      # database
      assert_db_contains(Message, actual)
    end

    test "valid (message with answers)", %{asset: asset} do
      message = to_message(asset.id, "test message", ["A", "B", "C"])
      {:ok, actual} = DispatcherMessageAgent.new(message)

      expected = %{
        id: actual.id,
        dispatcher_id: nil,
        acknowledge_id: nil,
        answer: nil,
        answers: message.answers,
        asset_id: asset.id,
        group_id: nil,
        message: message.message,
        timestamp: message.timestamp,
        server_timestamp: actual.server_timestamp
      }

      # return
      assert actual == expected

      # store
      assert DispatcherMessageAgent.all() == [actual]

      # database
      assert_db_contains(Message, actual)
    end

    test "invalid (missing message)", %{asset: asset} do
      message = to_message(asset.id, nil, nil)

      actual = DispatcherMessageAgent.new(message)
      assert_ecto_error(actual)
    end

    test "invalid (missing asset)" do
      message = to_message(nil, "test message", nil)

      actual = DispatcherMessageAgent.new(message)
      assert_ecto_error(actual)
    end

    test "invalid (message with <2 answers)", %{asset: asset} do
      message = to_message(asset.id, "test message", ["A"])
      actual = DispatcherMessageAgent.new(message)
      assert_ecto_error(actual)
    end
  end

  describe "mass recipients -" do
    test "valid (new message)", %{asset: asset} do
      asset_ids = [asset.id, asset.id + 1]
      message = "test mass message"

      {:ok, [msg_1, msg_2]} =
        DispatcherMessageAgent.new_mass_message(asset_ids, message, nil, nil, NaiveDateTime.utc_now())

      # return
      assert msg_1.asset_id == asset.id
      assert msg_1.message == message

      assert msg_2.asset_id == asset.id + 1
      assert msg_2.message == message

      assert !is_nil(msg_1.group_id)
      assert !is_nil(msg_2.group_id)
      assert msg_1.group_id == msg_2.group_id

      # store
      assert DispatcherMessageAgent.all() == [msg_2, msg_1]

      # database
      assert_db_contains(Message, [msg_1, msg_2])
    end

    test "valid (message with answers)", %{asset: asset} do
      asset_ids = [asset.id, asset.id + 1]
      message = "test mass message"
      answers = ["A", "B"]

      {:ok, [msg_1, msg_2]} =
        DispatcherMessageAgent.new_mass_message(
          asset_ids,
          message,
          nil,
          answers,
          NaiveDateTime.utc_now()
        )

      # return
      assert msg_1.answers == answers
      assert msg_2.answers == answers

      # store
      assert DispatcherMessageAgent.all() == [msg_2, msg_1]

      # database
      assert_db_contains(Message, [msg_2, msg_1])
    end

    test "invalid (missing message)", %{asset: asset} do
      asset_ids = [asset.id, asset.id + 1]
      message = nil

      actual =
        DispatcherMessageAgent.new_mass_message(asset_ids, message, nil, nil, NaiveDateTime.utc_now())

      assert actual == {:error, :invalid_message}
    end

    test "invalid (no asset ids)" do
      asset_ids = []
      message = "Valid message"

      actual =
        DispatcherMessageAgent.new_mass_message(asset_ids, message, nil, nil, NaiveDateTime.utc_now())

      assert actual == {:error, :invalid_asset_ids}
    end

    test "invalid (message within <2 answers)", %{asset: asset} do
      asset_ids = [asset.id, asset.id + 1]
      message = "test mass message"
      answers = ["A"]

      actual =
        DispatcherMessageAgent.new_mass_message(
          asset_ids,
          message,
          nil,
          answers,
          NaiveDateTime.utc_now()
        )

      assert actual == {:error, :invalid_answers}
    end

    test "valid (multiple of the same asset)", %{asset: asset} do
      asset_ids = [asset.id, asset.id]
      message = "test mass message"

      {:ok, messages} =
        DispatcherMessageAgent.new_mass_message(asset_ids, message, nil, nil, NaiveDateTime.utc_now())

      # return
      assert length(messages) == 1

      # store
      assert DispatcherMessageAgent.all() == messages

      # database
      assert_db_contains(Message, messages)
    end
  end

  describe "acknowledge -" do
    test "valid (unacknowledged message)", %{asset: asset} do
      message = to_message(asset.id, "test message", nil)
      {:ok, initial} = DispatcherMessageAgent.new(message)
      assert initial.acknowledge_id == nil

      {:ok, actual} =
        DispatcherMessageAgent.acknowledge(initial.id, nil, nil, NaiveDateTime.utc_now())

      # return
      assert actual.acknowledge_id != nil

      # store
      assert DispatcherMessageAgent.all() == [actual]

      # database
      assert_db_contains(Message, actual)
      refute_db_contains(Message, initial)
    end

    test "valid (answer in response)", %{asset: asset} do
      expected_answer = "A"

      message = to_message(asset.id, "test message", [expected_answer, "B"])
      {:ok, initial} = DispatcherMessageAgent.new(message)

      {:ok, actual} =
        DispatcherMessageAgent.acknowledge(
          initial.id,
          expected_answer,
          nil,
          NaiveDateTime.utc_now()
        )

      # return
      assert actual.answer == expected_answer

      # store
      assert DispatcherMessageAgent.all() == [actual]

      # database
      assert_db_contains(Message, actual)
      refute_db_contains(Message, initial)
    end

    test "invalid (id does not exist)" do
      actual = DispatcherMessageAgent.acknowledge(-1, nil, nil, NaiveDateTime.utc_now())
      assert actual == {:error, :invalid_id}
    end

    test "invalid (already acknowledged)", %{asset: asset} do
      {:ok, message} = DispatcherMessageAgent.new(to_message(asset.id, "test message", nil))
      DispatcherMessageAgent.acknowledge(message.id, nil, nil, NaiveDateTime.utc_now())
      actual = DispatcherMessageAgent.acknowledge(message.id, nil, nil, NaiveDateTime.utc_now())

      assert actual == {:error, :already_acknowledged}
    end

    test "invalid (answer not in answers)", %{asset: asset} do
      {:ok, message} =
        DispatcherMessageAgent.new(to_message(asset.id, "test message", ["A", "B"]))

      actual =
        DispatcherMessageAgent.acknowledge(
          message.id,
          "Wrong answer",
          nil,
          NaiveDateTime.utc_now()
        )

      assert actual == {:error, :invalid_answer}
    end
  end
end
