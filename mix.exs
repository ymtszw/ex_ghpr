defmodule ExGHPR.Mixfile do
  use Mix.Project

  @name "ghpr"

  def project do
    [
      app: :ex_ghpr,
      version: "0.2.0",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      escript: [
        main_module: ExGHPR.CLI,
        name: @name,
        path: Path.expand(Path.join(["~", ".mix", "escripts", @name])), # workaround until elixir 1.3
      ],
      deps: deps
     ]
  end

  def application do
    [
      applications: [
        :logger,
        :inets,
        :httpoison,
      ]
    ]
  end

  defp deps do
    [
      {:git_cli,        "~> 0.2"              },
      {:poison,         "~> 2.0"              },
      {:httpoison,      "~> 0.8"              },
      {:croma,          "~> 0.4"              },
      {:mix_test_watch, "~> 0.2", [only: :dev]},
    ]
  end
end
