use Croma

defmodule ExOpenpr.CLI do
  alias Croma.Result, as: R
  alias ExOpenpr.Config
  alias ExOpenpr.GlobalConfig, as: GConf
  alias ExOpenpr.LocalConfig, as: LConf

  def main(argv) do
    {opts, _args, _err} = OptionParser.parse(argv,
      switches: [
        version: :boolean,
        local:   :boolean,
        global:  :boolean,
      ],
      aliases: [
        v: :version,
        l: :local,
        g: :global,
      ]
    )
    if opts[:version] do
      IO.puts("#{Config.cmd_name} - #{Config.cmd_version}")
    else
      {:ok, conf} = case Config.load do
        {:error, :enoent} -> Config.init
        ok_tuple          ->
          cond do
            opts[:local]  -> LConf.init(File.cwd!)
            opts[:global] -> GConf.init
            true          -> ok_tuple
          end
      end
    end
  end
end
