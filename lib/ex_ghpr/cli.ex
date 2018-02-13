use Croma

defmodule ExGHPR.CLI do
  alias ExGHPR.Util
  alias Croma.Result, as: R
  alias ExGHPR.Config
  alias ExGHPR.LocalConfig, as: LConf
  alias ExGHPR.CLI.{Create, Search}

  @string_options [
    {nil, :fork}, # Does not have short hand alias, since it is confusing with "--force"
    {:c, :configure},
    {:r, :remote},
    {:t, :title},
    {:m, :message},
    {:b, :base},
  ]

  @aliases [v: :version, l: :line] ++ tl(@string_options)

  # Generate validators for each string-value options
  for {_, opt} <- @string_options do
    @doc false
    defun unquote(:"validate_#{opt}")(value :: nil | boolean | String.t, default :: nil | String.t \\ nil) :: String.t do
      case value do
        n when is_nil(n)     -> default
        b when is_boolean(b) -> Util.exit_with_error("--#{unquote(opt)} option must take String value")
        str                  -> str
      end
    end
  end

  def main(argv) do
    {opts, args0, _err} = OptionParser.parse(argv, [aliases: @aliases, switches: [line: :integer]])

    cond do
      opts[:version] ->
        IO.puts("#{Config.cmd_name()} - #{Config.cmd_version()}")
      c = opts[:configure] ->
        configure_ghpr(c)
      true ->
        case args0 do
          ["create" | tl] -> create_ghpr(opts, tl)
          ["search" | tl] -> search_ghpr(opts, tl)
          args1           -> create_ghpr(opts, args1)
        end
    end
  end

  defunp configure_ghpr(switch :: term) :: R.t(map) do
    "local"  -> LConf.init(File.cwd!())
    "global" -> Config.init()
    _other   -> Util.exit_with_error("$ #{Config.cmd_name()} --configure {local|global}")
  end

  defunp create_ghpr(opts :: Keyword.t, _args :: [term]) :: :ok | {:error, term} do
    exec_with_git_repository(fn current_repo, u_n, t, lconf ->
      current_branch = Util.fetch_current_branch(current_repo)
      Create.ensure_current_branch_pushed_to_origin(current_repo, current_branch, u_n, t)
      |> R.map_error(&Util.exit_with_error(inspect(&1)))
      |> R.get()
      |> Util.puts_last_line()

      Create.ensure_pull_requested(opts, current_repo, current_branch, u_n, t, lconf["tracker_url"])
      |> R.map_error(&Util.exit_with_error(inspect(&1)))
      |> R.get()
      |> Util.copy_to_clipboard_and_echo()
    end)
  end

  defunp search_ghpr(opts :: Keyword.t, args :: [term]) :: :ok | {:error, term} do
    exec_with_git_repository(fn current_repo, u_n, t, _lconf ->
      file_name_or_sha_hash = hd(args)
      sha_hash =
        case opts[:line] do
          nil -> file_name_or_sha_hash
          num ->
            Search.blame(current_repo, file_name_or_sha_hash, num)
            |> Croma.Result.map_error(&Util.exit_with_error(inspect(&1)))
            |> Croma.Result.get()
        end

      current_repo
      |> Util.fetch_remote_owner_repo(validate_remote(opts[:remote], "origin"))
      |> R.get()
      |> Search.search_pull_requests_and_list_url(u_n, t, sha_hash)
      |> R.map_error(&Util.exit_with_error(&1))
      |> R.get()
      |> Enum.each(fn html_url ->
        IO.puts(html_url)
      end)
    end)
  end

  defun exec_with_git_repository(block :: (struct, binary, binary, map -> :ok)) :: :ok do
    cwd = File.cwd!
    current_conf = Config.ensure_cwd(cwd)
    case current_conf[cwd] do
      nil   -> Util.exit_with_error("Not a git repository")
      lconf ->
        current_repo   = %Git.Repository{path: cwd}
        %{"username" => u_n, "token" => t} = current_conf["auth"][lconf["auth_user"]]
        block.(current_repo, u_n, t, lconf)
    end
  end
end
