use Croma

defmodule ExGHPR.AuthConfig do
  alias ExGHPR.Util
  alias ExGHPR.{Config, Github}

  defun init_default(current_conf :: v[map]) :: Croma.Result.t(map) do
    username = Util.prompt_until_pattern_match("Enter your Github username: ", ~r/\A\S+\n\Z/)
    token = Github.try_auth(username)
    Config.save_auth(%{"$default" => %{"username" => username, "token" => token}}, current_conf)
  end

  defun init_local(current_conf :: v[map]) :: String.t do
    username = Util.prompt_until_pattern_match("Enter your Github username: ", ~r/\A\S+\n\Z/)
    case Config.get_auth(current_conf, username) do
      {:error, :not_found} ->
        token = Github.try_auth(username)
        case Config.save_auth(%{username => %{"username" => username, "token" => token}}, current_conf) do
          {:error, reason} -> Util.exit_with_error(inspect(reason))
          {:ok, _}         -> username
        end
      {:ok, _map} ->
        username
    end
  end
end

defmodule ExGHPR.LocalConfig do
  use Croma.Struct, fields: [
    username:    Croma.TypeGen.nilable(Croma.String),
    token:       Croma.TypeGen.nilable(Croma.String),
    tracker_url: Croma.TypeGen.nilable(Croma.String),
  ]
  alias ExGHPR.{Config, AuthConfig}
  alias ExGHPR.LocalGitRepositoryPath, as: LPath

  defun init(cwd :: v[LPath.t], current_conf :: v[map]) :: Croma.Result.t(map) do
    IO.puts "Configuring git repository: #{cwd}"
    {:ok, %{"username" => default_username}} = Config.get_auth(current_conf, "$default")
    yn =
      IO.gets("Use default user? (#{default_username}) [Y/N]: ")
      |> String.trim_trailing()
      |> String.downcase()
    auth =
      case yn do
        "y" -> "$default"
        "n" -> AuthConfig.init_local(current_conf)
        _   -> init(cwd, current_conf)
      end
    tu = prompt_tracker_url()
    Config.save_local_conf(%{cwd => %{"auth_user" => auth, "tracker_url" => tu}}, current_conf)
  end

  defunp prompt_tracker_url() :: nil | String.t do
    tracker_url = IO.gets("(Optional) Enter issue tracker url (e.g. https://github.com/YuMatsuzawa/ex_ghpr/issues): ")
    case String.trim_trailing(tracker_url) do
      ""  -> nil
      url ->
        case validate_tracker_url(url) do
          {:error, :trailing_slash} -> IO.puts("Must not end with slash.") && prompt_tracker_url()
          {:error, _invalid_url   } -> IO.puts("Invalid URL.") && prompt_tracker_url()
          {:ok   , valid_url      } -> valid_url
        end
    end
  end

  defunp validate_tracker_url(url :: String.t) :: Croma.Result.t(String.t) do
    case URI.parse(url) do
      %URI{scheme: nil} -> {:error, :no_scheme}
      %URI{host: nil  } -> {:error, :no_host}
      _ok               -> if String.ends_with?(url, "/"), do: {:error, :trailing_slash}, else: {:ok, url}
    end
  end
end

defmodule ExGHPR.LocalGitRepositoryPath do
  @type t :: Path.t

  defun validate(term :: term) :: Croma.Result.t(t) do
    if File.dir?(Path.join(term, ".git")) do
      {:ok, term}
    else
      {:error, {:invalid_value, [__MODULE__]}}
    end
  end
end

defmodule ExGHPR.Config do
  @moduledoc """
  Configuration for `ghpr` will be stored in `~/.mix/config/ghpr` in the following format:

      {
        "auth": {
          "$default": { "username": "GlobalUser", "token": "Token" },
          "AnotherUser": { "username": "AnotherUser", "token": "Token" },
          ...
        },
        "path/to/local/repo": {
          "auth_user": "$default",
          "tracker_url": "https://github.com/GlobalUser/repo/issues"
        },
        "path/to/another/repo": {
          "auth_user": "AnotherUser",
          "tracker_url": null
        }
      }

  Deleting the above file can reset local configurations.
  Note that already issued personal access token are still active,
  so you need to revoke it first before re-configuration.
  """

  alias Croma.Result, as: R
  alias ExGHPR.{AuthConfig, LocalConfig}
  alias ExGHPR.LocalGitRepositoryPath, as: LPath

  @cmd_name    Mix.Project.config[:escript][:name]
  @cmd_version Mix.Project.config[:version]
  @config_file Path.join(["~", ".config", @cmd_name])

  def cmd_name(),    do: @cmd_name
  def cmd_version(), do: @cmd_version

  defun init() :: R.t(map) do
    IO.puts "#{@cmd_name} - #{@cmd_version}"
    AuthConfig.init_default(%{})
    |> R.map(fn conf ->
      init_lconf_or_nil(File.cwd!(), conf) || conf
    end)
  end

  defun load() :: R.t(map) do
    File.read(Path.expand(@config_file)) # expand runtime to support precompiled binary
    |> R.bind(&Poison.decode/1)
  end

  defun load!() :: map do
    case load() do
      {:error, _   } -> %{}
      {:ok, current} -> current
    end
  end

  defun ensure_cwd(cwd :: Path.t) :: map do
    case load() do
      {:error, _}                -> init() |> R.get()
      {:ok, %{^cwd => _} = conf} -> conf
      {:ok, conf}                -> init_lconf_or_nil(cwd, conf) || conf
    end
  end

  defunp init_lconf_or_nil(cwd :: Path.t, current_conf :: map) :: nil | map do
    case LPath.validate(cwd) do
      {:ok, repo} -> LocalConfig.init(repo, current_conf) |> R.get()
      {:error, _} -> nil
    end
  end

  defun save_local_conf(lconf :: v[map], current_conf :: v[map]) :: R.t(map) do
    save(Map.merge(current_conf, lconf))
  end

  defun save_auth(aconf :: v[map], current_conf :: v[map]) :: R.t(map) do
    new_aconf = Map.merge(current_conf["auth"] || %{}, aconf)
    new_conf = Map.put(current_conf, "auth", new_aconf)
    save(new_conf)
  end

  defun get_auth(current_conf :: v[map], username :: v[String.t]) :: R.t(map) do
    case Map.get(current_conf["auth"], username) do
      nil -> {:error, :not_found}
      map -> {:ok,    map       }
    end
  end

  defunp save(conf :: v[map]) :: R.t(map) do
    case File.write(Path.expand(@config_file), Poison.encode!(conf)) do
      :ok -> {:ok, conf}
      e   -> e
    end
  end
end
