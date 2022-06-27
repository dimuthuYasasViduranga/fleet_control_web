defmodule FleetControlWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :fleet_control_web,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: alias_envs()
    ]
  end

  def application do
    mod = {FleetControlWeb.Application, []}
    apps = [:logger, :runtime_tools]

    case Mix.env() do
      :test -> [extra_applications: apps]
      _ -> [mod: mod, extra_applications: apps]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps() do
    [
      # web
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.3"},
      {:plug_cowboy, "~> 2.0"},
      {:corsica, "~> 1.1"},
      {:guardian, "~> 2.2"},
      {:appsignal_phoenix, "~> 2.0"},
      {:decorator, "~> 1.2"},

      # dispatch
      {:topo, "~> 0.4.0"},
      {:geo, "~> 3.1"},
      {:distance, "~> 1.0"},
      {:joken, "~> 2.0"},
      {:gps_gate_rest, git: "https://github.com/Haultrax/gps_gate_rest.git", tag: "0.5.0"},
      {:eastar, "~> 0.5"},
      {:azure_ad_openid, "~> 0.3.2"},
      {:slack_logger_backend,
       git: "https://github.com/whossname/slack_logger_backend.git", tag: "0.2.4", only: [:prod]},

      # this overrides a dependency in cluster graph
      {:hps_data, git: "https://github.com/Haultrax/hps_data.git", tag: "3.0.0"},
      {:syncro, git: "https://github.com/Haultrax/syncro.git", tag: "0.0.1"},

      # test
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:bureaucrat, "~> 0.2.7", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      check: [
        "compile --warnings-as-errors --force",
        "format --check-formatted",
        "credo"
      ],
      "test.setup": [
        "ecto.create -r HpsData.Repo --quiet",
        "ecto.migrate",
        # fleetops seeds
        "run ./deps/hps_data/priv/repo/seeds/time_usage_types.exs",
        "run ./deps/hps_data/priv/repo/seeds/asset_types.exs",
        "run ./deps/hps_data/priv/repo/seeds/losses/test.exs",
        # fleet control seeds
        "run ./deps/hps_data/priv/repo/seeds/dispatch/pre_start_ticket_status_types/default.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/operator_message_types/default.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/time_code_groups.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/time_codes/simple.exs",
        "run ./priv/test_data_seeds.exs"
      ],
      "test.test_seeds": ["run ./priv/test_data_seeds.exs"],
      "test.drop": ["ecto.drop -r HpsData.Repo"],
      "test.migrate": ["ecto.migrate -r HpsData.Repo"],
      "test.unit": ["test test/unit"],
      "test.agent": ["test test/integration/agents"],
      "test.conn": ["test test/integration/conn"],
      "test.channel": ["test test/integration/channel"]
    ]
  end

  defp alias_envs() do
    [
      check: :test,
      "test.test_seeds": :test,
      "test.setup": :test,
      "test.drop": :test,
      "test.migrate": :test,
      "test.unit": :test,
      "test.agent": :test,
      "test.conn": :test,
      "test.channel": :test
    ]
  end
end
