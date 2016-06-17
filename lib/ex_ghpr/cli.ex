use Croma

defmodule ExGHPR.CLI do
  alias Croma.Result, as: R
  import ExGHPR.Util
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
    current_conf = Config.ensure_cwd(cwd)
    case current_conf[cwd] do
      nil   -> exit_with_error("Not a git repository")
      lconf ->
        current_repo   = %Git.Repository{path: cwd}
        current_branch = fetch_current_branch(current_repo)
        {u_n, t}       = choose_credentials(lconf, current_conf["global"])
        ensure_current_branch_pushed_to_origin(current_repo, current_branch, u_n, t)
        |> R.map_error(&exit_with_error(inspect(&1)))
        |> R.get
        |> puts_last_line
        ensure_pull_requested(opts, current_repo, current_branch, u_n, t, lconf["tracker_url"])
        |> R.map_error(&exit_with_error(inspect(&1)))
        |> R.get
        |> IO.puts
    end
  end

  defunp fetch_current_branch(%Git.Repository{} = repo) :: String.t do
    case Git.rev_parse(repo, ~w(--abbrev-ref HEAD)) do
      {:ok, "HEAD\n"} -> exit_with_error("Cannot open PR from detached HEAD")
      {:ok, name    } -> String.rstrip(name, ?\n)
    end
  end

  defunp choose_credentials(%{"username" => lun, "token" => lt}, %{"username" => gun, "token" => gt}) :: {String.t, String.t} do
    case {lun, lt} do
      {nil, _} -> {gun, gt}
      creds    -> creds
    end
  end

  defunp ensure_current_branch_pushed_to_origin(
      %Git.Repository{} = repo,
      current_branch :: v[String.t],
      username       :: v[String.t],
      token          :: v[String.t]) :: R.t(term) do
    origin_url = case Git.remote(repo, ["get-url", "origin"]) do
      {:error, _  } -> exit_with_error("Cannot find `origin` remote")
      {:ok   , url} -> url
    end
    origin_url_with_auth = case URI.parse(origin_url) do
      %URI{scheme: "https", host: "github.com", path: path} ->
        "https://#{username}:#{token}@github.com#{String.rstrip(path, ?\n)}" # Yes, this way you can push without entering password
      _ssh_url -> origin_url
    end
    Git.push(repo, [origin_url_with_auth, current_branch])
  end

  defunp ensure_pull_requested(
      opts           :: Keyword.t,
      %Git.Repository{} = repo,
      current_branch :: v[String.t],
      username       :: v[String.t],
      token          :: v[String.t],
      tracker_url    :: nil | String.t) :: R.t(term) do
    api_url = Github.pull_request_api_url(repo, validate_remote(opts[:remote], "origin"))
    |> R.map_error(&exit_with_error(inspect(&1)))
    |> R.get
    head = case validate_fork(opts[:fork]) do
      nil  -> current_branch
      fork -> "#{fork}:#{current_branch}"
    end
    base = validate_base(opts[:base], "master")
    Github.existing_pull_request(api_url, username, token, head, base)
    |> R.bind(fn
      nil ->
        title = validate_title(opts[:title], current_branch)
        body = validate_message(opts[:message], calc_body(current_branch, tracker_url))
        Github.create_pull_request(api_url, username, token, title, head, base, body)
      url -> {:ok, url}
    end)
  end

  defunp search_ghpr(_opts :: Keyword.t, _args :: [term]) :: :ok | {:error, term} do
    exit("NYI")
  end

  defp   calc_body(_branch_name, nil), do: ""
  defunp calc_body(branch_name :: v[String.t], tracker_url) :: String.t do
    case Regex.named_captures(~r/\A(?<issue_num>\d+)_/, branch_name) do
      %{"issue_num" => num} -> "#{tracker_url}/#{num}"
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
