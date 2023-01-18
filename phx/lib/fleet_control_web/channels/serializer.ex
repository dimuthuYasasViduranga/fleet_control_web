defmodule FleetControlWeb.Serializer do

  @behaviour Phoenix.Socket.Serializer

  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast

  @impl true
  def fastlane!(%Broadcast{payload: %{}} = msg) do
    data = [nil, nil, msg.topic, msg.event, msg.payload]
    data |> encode("broadcast")
  end

  @impl true
  def encode!(%Reply{} = reply) do
    data = [
      reply.join_ref,
      reply.ref,
      reply.topic,
      "phx_reply",
      %{status: reply.status, response: reply.payload}
    ]
    data |> encode("msg-reply")
  end


  def encode!(%Message{payload: %{}} = msg) do
    data = [msg.join_ref, msg.ref, msg.topic, msg.event, msg.payload]
    data |> encode("msg")
  end

  defp encode(data, kind) do
    [_,_,topic, event, _] = data
    bin = data |> Jason.encode_to_iodata! |> :zlib.gzip

    Appsignal.increment_counter(kind, 1, %{recipient: topic, event: event})
    Appsignal.increment_counter("#{kind}-payload-size", :erlang.byte_size(bin), %{event: event})

    {:socket_push, :binary, bin}
  end

  @impl true
  def decode!(message, opts) do
    decoded_msg = message |> :zlib.gunzip |> Phoenix.json_library().decode!
    [join_ref, ref, topic, event, payload | _] = decoded_msg

    Appsignal.increment_counter("incoming-msg", 1, %{recipient: topic, event: event})
    Appsignal.increment_counter("incoming-msg-size", :erlang.byte_size(message), %{event: event})

    %Message{
      topic: topic,
      event: event,
      payload: payload,
      ref: ref,
      join_ref: join_ref
    }
  end
end
