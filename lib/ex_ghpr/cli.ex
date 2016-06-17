use Croma

defmodule ExGHPR.CLI do
  alias Croma.Result, as: R
  alias ExGHPR.{Config, Github}
  alias ExGHPR.GlobalConfig, as: GConf
  alias ExGHPR.LocalConfig, as: LConf

  def main(argv) do
    {opts, _args, _err} = OptionParser.parse(argv,
      switches: [
        version:   :boolean,
        configure: :string,
      ],
      aliases: [
        v: :version,
        c: :configure,
      ]
    )
    cond do
      opts[:version]   -> IO.puts("#{Config.cmd_name} - #{Config.cmd_version}")
      opts[:configure] ->
        case opts[:configure] do
          "local"  -> LConf.init(File.cwd!)
          "global" -> GConf.init
        end
      true             ->
        cwd = File.cwd!
        current_conf = load_conf(cwd)
        gconf = current_conf["global"]
        case current_conf[cwd] do
          nil   -> exit("Not a git repository")
          lconf ->
            current_repo = %Git.Repository{path: cwd}
            current_branch = case Git.rev_parse(current_repo, ~w(--abbrev-ref HEAD)) do
              {:ok, "HEAD\n"} -> exit("Cannot open PR from detached HEAD")
              {:ok, name    } -> String.rstrip(name, ?\n)
            end
            # {:ok, _} = Git.push(current_repo, ["--set-upstream", "origin", current_branch])
            url = lconf["origin_pr_url"]
            {u_n, t} = case {lconf["username"], lconf["token"]} do
              {nil, _} -> {gconf["username"], gconf["token"]}
              creds    -> creds
            end
            body = calc_body(current_branch, lconf)
            case Github.create_pull_request(url, u_n, t, current_branch, current_branch, "master", body) do
              {:ok   , html_url     } -> IO.puts(html_url)
              {:error, :unauthorized} -> exit("Unauthorized. Try `$ #{Config.cmd_name} --configure local`")
              {:error, reason       } -> IO.inspect(reason)
            end
        end
    end
  end

  defunp load_conf(cwd :: Path.t) :: map do
    case Config.load do
      {:error, _}                -> Config.init |> R.get
      {:ok, %{^cwd => _} = conf} -> conf
      {:ok, _conf}               -> LConf.init(cwd) |> R.get
    end
  end

  defun calc_body(branch_name :: v[String.t], %{"tracker_url" => t_u}) :: String.t do
    case Regex.named_captures(~r/\A(?<issue_num>\d+)_/, branch_name) do
      %{"issue_num" => num} -> "#{t_u}/#{num}"
      _                     -> ""
    end
  end
end
