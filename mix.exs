defmodule ExGHPR.Mixfile do
  use Mix.Project

  @name "ghpr"
  @github_url "https://github.com/ymtszw/ex_ghpr"

  def project() do
    [
      app: :ex_ghpr,
      description: "CLI to work with GitHub Pull Request",
      version: "0.3.1",
      elixir: "~> 1.4",
      elixirc_options: [warnings_as_errors: true],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      escript: [
        main_module: ExGHPR.CLI,
        name: @name,
      ],
      deps: [
        {:git_cli,        "~> 0.2"              },
        {:poison,         "~> 2.0"              },
        {:httpoison,      "~> 0.8"              },
        {:croma,          "~> 0.4"              },
        {:mix_test_watch, "~> 0.2", [only: :dev]},
        {:credo,          "~> 0.8", [only: :dev]},
      ],
      source_url: @github_url,
      package: [
        files: ["lib", "mix.exs", "LICENSE", "README.md"],
        licenses: ["BSD-3-Clause"],
        maintainers: ["ymtszw"],
        links: %{"GitHub" => @github_url},
      ],
     ]
  end
end
