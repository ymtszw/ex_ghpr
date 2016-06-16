defmodule ExOpenpr.Mixfile do
  use Mix.Project

  @name "openpr"

  def project do
    [
      app: :ex_openpr,
       version: "0.0.1",
       elixir: "~> 1.2",
       build_embedded: Mix.env == :prod,
       start_permanent: Mix.env == :prod,
       escript: [
         main_module: ExOpenpr.CLI,
         name: @name,
         path: Path.expand(Path.join(["~", ".mix", "escripts", @name])), # workaround until elixir 1.3
       ],
       deps: deps
     ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:croma, [github: "skirino/croma", ref: "master"]},
    ]
  end
end
