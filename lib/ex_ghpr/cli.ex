use Croma

defmodule ExGHPR.CLI do
  alias Croma.Result, as: R
  alias ExGHPR.{Config, Github}
  alias ExGHPR.GlobalConfig, as: GConf
  alias ExGHPR.LocalConfig, as: LConf

  @string_options [
    :configure,
    :remote,
    :title,
    :message,
    :base,
    :fork,
  ]

  def main(argv) do
    {opts, args0, _err} = OptionParser.parse(argv,
      aliases: [
        v: :version,
      ] ++ Enum.filter_map(@string_options,
      fn atom -> atom != :fork end,
      fn atom ->
        {Atom.to_string(atom) |> String.at(0) |> String.to_atom, atom}
      end)
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
    _other   -> exit_with_error("$ #{Config.cmd_name} --configure {local|global}")
  end

  defunp create_ghpr(opts :: Keyword.t, _args :: [term]) :: :ok | {:error, term} do
    cwd = File.cwd!
    current_conf = load_conf(cwd)
    gconf = current_conf["global"]
    case current_conf[cwd] do
      nil   -> exit_with_error("Not a git repository")
      lconf ->
        current_repo = %Git.Repository{path: cwd}
        current_branch = case Git.rev_parse(current_repo, ~w(--abbrev-ref HEAD)) do
          {:ok, "HEAD\n"} -> exit_with_error("Cannot open PR from detached HEAD")
          {:ok, name    } -> String.rstrip(name, ?\n)
        end
        {u_n, t} = case {lconf["username"], lconf["token"]} do
          {nil, _} -> {gconf["username"], gconf["token"]}
          creds    -> creds
        end
        case ensure_current_branch_pushed_to_origin(current_repo, current_branch, u_n, t) do
          {:error, error} -> exit_with_error(inspect(error))
          {:ok   , _    } -> :ok
        end
        {:ok, url} = Github.pull_request_api_url(cwd, validate_remote(opts[:remote], "origin"))
        title = validate_title(opts[:title], current_branch)
        head = case validate_fork(opts[:fork]) do
          nil  -> current_branch
          fork -> "#{fork}:#{current_branch}"
        end
        body = validate_message(opts[:message], calc_body(current_branch, lconf))
        case Github.create_pull_request(url, u_n, t, title, head, validate_base(opts[:base], "master"), body) do
          {:ok   , html_url     } -> IO.puts(html_url)
          {:error, :unauthorized} -> exit_with_error("Unauthorized. Try `$ #{Config.cmd_name} --configure local`")
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

  defunp ensure_current_branch_pushed_to_origin(%Git.Repository{} = repo,
                                                current_branch :: v[String.t],
                                                username       :: v[String.t],
                                                token          :: v[String.t]) :: R.t(term) do
    origin_url = case Git.remote(repo, ["get-url", "origin"]) do
      {:error, _} -> exit_with_error("Cannot find `origin` remote")
      {:ok, url } -> url
    end
    origin_url_with_auth = case URI.parse(origin_url) do
      %{scheme: "https", host: "github.com", path: path} ->
        "https://#{username}:#{token}@github.com#{path}" # Yes, this way you can push without entering password
      _ssh_url -> origin_url
    end
    Git.push(repo, ["--set-upstream", origin_url_with_auth, current_branch])
  end

  defp   calc_body(_branch_name, %{"tracker_url" => nil}), do: ""
  defunp calc_body(branch_name :: v[String.t], %{"tracker_url" => t_u}) :: String.t do
    case Regex.named_captures(~r/\A(?<issue_num>\d+)_/, branch_name) do
      %{"issue_num" => num} -> "#{t_u}/#{num}"
      _                     -> ""
    end
  end

  for key <- @string_options do
    defunp unquote(:"validate_#{key}")(value :: nil | boolean | String.t, default :: nil | String.t \\ nil) :: String.t do
      case value do
        n when is_nil(n)     -> default
        b when is_boolean(b) -> exit_with_error("--#{unquote(key)} option must take String value")
        str                  -> str
      end
    end
  end

  defunp exit_with_error(message :: v[String.t]) :: no_return do
    IO.puts(:stderr, message)
    exit({:shutdown, 1})
  end
end
