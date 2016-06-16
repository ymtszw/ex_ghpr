use Croma

defmodule ExOpenpr.CLI do
  @mix_version Mix.Project.config[:version]

  def main(argv) do
    {opts, _args, _err} = OptionParser.parse(argv,
      switches: [
        version: :boolean,
      ],
      aliases: [
        v: :version,
      ]
    )
    if opts[:version], do: IO.puts("#{@mix_version}")
  end
end
