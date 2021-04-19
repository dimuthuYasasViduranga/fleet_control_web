defmodule DispatchWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :dispatch_web,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: alias_envs()
    ]
  end

  def application, do: application(Mix.env())

  defp application(:test) do
    [
      extra_applications: [:logger, :runtime_tools, :postgrex, :ecto]
    ]
  end

  defp application(_) do
    [
      mod: {DispatchWeb.Application, []},
      extra_applications: [:logger, :runtime_tools, :postgrex, :ecto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps() do
    [
      # web
      {:phoenix, "~> 1.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.2"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:cowlib, "~> 2.9.0", override: true},
      {:plug_cowboy, "~> 2.0"},
      {:corsica, "~> 1.1"},
      {:guardian, "~> 1.1"},
      {:appsignal_phoenix, "~> 2.0"},
      {:decorator, "~> 1.2"},

      # dispatch
      {:topo, "~> 0.3.0"},
      {:geo, "~> 3.1"},
      {:joken, "~> 2.0"},
      {:gps_gate_rest, git: "https://github.com/Haultrax/gps_gate_rest.git", tag: "0.4.0"},
      {:eastar, "~> 0.5"},
      {:azure_ad_openid, "~> 0.2"},
      {:poison, "~> 3.0"},

      # this overrides a dependency in cluster graph
      {:hps_data,
       git: "https://github.com/Haultrax/hps_data.git", branch: "pre-start", override: true},

      # patch fix
      {:hackney, "1.15.2", override: true},

      # test
      {:mix_test_watch, "~> 0.9", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:bureaucrat, "~> 0.2.7", only: :test}
    ]
  end

  defp aliases do
    [
      "test.setup": [
        "ecto.create -r HpsData.Repo --quiet",
        "ecto.migrate",
        # fleetops seeds
        "run ./deps/hps_data/priv/repo/seeds/time_usage_types.exs",
        "run ./deps/hps_data/priv/repo/seeds/asset_types.exs",
        "run ./deps/hps_data/priv/repo/seeds/losses/test.exs",
        # fleet control seeds
        "run ./deps/hps_data/priv/repo/seeds/dispatch/pre_start_ticket_status_types/default.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/material_type/test.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/operator_message_types/default.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/operators/test.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/time_code_groups.exs",
        "run ./deps/hps_data/priv/repo/seeds/dispatch/time_codes/default.exs",
        "run ./priv/test_data_seeds.exs"
      ],
      "test.test_seeds": ["run ./priv/test_data_seeds.exs"],
      "test.drop": ["ecto.drop -r HpsData.Repo"],
      "test.migrate": ["ecto.migrate -r HpsData.Repo"],
      "test.unit": ["test --only unit"],
      "test.agent": ["test --only agent"],
      "test.conn": ["test --only conn"],
      "test.channel": ["test --only channel"]
    ]
  end

  defp alias_envs() do
    [
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
