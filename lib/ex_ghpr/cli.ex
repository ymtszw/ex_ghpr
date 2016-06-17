use Croma

defmodule ExGHPR.CLI do
  alias Croma.Result, as: R
  alias ExGHPR.{Config, Github}
  alias ExGHPR.GlobalConfig, as: GConf
  alias ExGHPR.LocalConfig, as: LConf

  def main(argv) do
    {opts, args0, _err} = OptionParser.parse(argv,
      strict: [
        version:   :boolean,
        configure: :string,
        remote:    :string,
        title:     :string,
        message:   :string,
        base:      :string,
        fork:      :string,
      ],
      aliases: [
        v: :version,
        c: :configure,
        r: :remote,
        t: :title,
        m: :message,
        b: :base,
      ]
    )
    cond do
      opts[:version]         -> IO.puts("#{Config.cmd_name} - #{Config.cmd_version}")
      c = opts[:configure]   -> configure_ghpr(c)
      true                   ->
        case args0 do
          ["create" | tl] -> create_ghpr(opts, tl)
          ["search" | tl] -> search_ghpr(opts, tl)
          args1           -> create_ghpr(opts, args1)
        end
    end
  end

  defunp configure_ghpr(switch :: term) :: R.t(map) do
    "local"  -> LConf.init(File.cwd!)
    "global" -> GConf.init
    _other   -> exit("$ #{Config.cmd_name} --configure {local|global}")
  end

  defunp create_ghpr(opts :: Keyword.t, _args :: [term]) :: :ok | {:error, term} do
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
        {:ok, url} = Github.pull_request_api_url(cwd, opts[:remote] || "origin")
        {u_n, t} = case {lconf["username"], lconf["token"]} do
          {nil, _} -> {gconf["username"], gconf["token"]}
          creds    -> creds
        end
        title = opts[:title] || current_branch
        head = case opts[:fork] do
          nil  -> current_branch
          fork -> "#{fork}:#{current_branch}"
        end
        body = opts[:message] || calc_body(current_branch, lconf)
        case Github.create_pull_request(url, u_n, t, title, head, opts[:base] || "master", body) do
          {:ok   , html_url     } -> IO.puts(html_url)
          {:error, :unauthorized} -> exit("Unauthorized. Try `$ #{Config.cmd_name} --configure local`")
          {:error, reason       } -> IO.inspect(reason)
        end
    end
  end

  defunp search_ghpr(_opts :: Keyword.t, _args :: [term]) :: :ok | {:error, term} do
    exit("NYI")
  end

  defunp load_conf(cwd :: Path.t) :: map do
    case Config.load do
      {:error, _}                -> Config.init |> R.get
      {:ok, %{^cwd => _} = conf} -> conf
      {:ok, _conf}               -> LConf.init(cwd) |> R.get
    end
  end

  defp   calc_body(_branch_name, %{"tracker_url" => nil}), do: ""
  defunp calc_body(branch_name :: v[String.t], %{"tracker_url" => t_u}) :: String.t do
    case Regex.named_captures(~r/\A(?<issue_num>\d+)_/, branch_name) do
      %{"issue_num" => num} -> "#{t_u}/#{num}"
      _                     -> ""
    end
  end
end
