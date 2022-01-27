defmodule DispatchWeb.Authorization.Decorator do
  use Decorator.Define, authorized: 1, only_in: 1

  @type reply :: {:reply, term, Phoenix.Socket.t()}

  @spec authorized(atom, term, Decorator.Decorate.Context.t()) :: reply
  def authorized(permission, body, %{args: [topic, _payload, socket]}) do
    quote do
      require Logger
      socket = unquote(socket)
      permission = unquote(permission)

      socket
      |> Map.get(:assigns, %{})
      |> Map.get(:permissions, %{})
      |> Map.get(permission, false)
      |> case do
        true ->
          unquote(body)

        _ ->
          user_id = socket.assigns[:current_user][:user_id]
          topic = unquote(topic)
          Logger.warn("[Unauthorized] User #{inspect(user_id)} cannot use topic: `#{topic}`")
          {:reply, {:error, %{error: :unauthorized}}, unquote(socket)}
      end
    end
  end

  @spec only_in(:test | :dev | :prod, term, Decorator.Decorate.Context.t()) :: reply
  def only_in(env, body, %{args: [topic, _payload, socket]}) do
    quote do
      require Logger

      mix_env =
        case Code.ensure_compiled(Mix) do
          {:module, _} -> Mix.env()
          _ -> :prod
        end

      socket = unquote(socket)
      correct_env = unquote(env) == mix_env

      case correct_env do
        true ->
          unquote(body)

        _ ->
          topic = unquote(topic)
          Logger.warn("[Unauthorized] Topic '#{topic}' only available in '#{unquote(env)}'")
          {:reply, {:error, %{error: :unauthorized}}, unquote(socket)}
      end
    end
  end
end
