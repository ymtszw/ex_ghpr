use Croma

defmodule ExGHPR.GlobalConfig do
  alias ExGHPR.{Config, Github}
  use Croma.Struct, fields: [
    username: Croma.String,
    token:    Croma.String,
  ]

  defun init :: Croma.Result.t(map) do
    {username, token} = Github.try_auth
    Config.save(%__MODULE__{username: username, token: token})
  end
end

defmodule ExGHPR.LocalConfig do
  alias ExGHPR.{Config, Github}
  alias ExGHPR.LocalGitRepositoryPath, as: LPath
  use Croma.Struct, fields: [
    username:    Croma.TypeGen.nilable(Croma.String),
    token:       Croma.TypeGen.nilable(Croma.String),
    tracker_url: Croma.TypeGen.nilable(Croma.String),
  ]

  defun init(cwd :: v[LPath.t]) :: Croma.Result.t(map) do
    IO.puts "Configuring git repository: #{cwd}"
    yn = IO.gets("Use default user? [Y/N]: ") |> String.rstrip(?\n) |> String.downcase
    {un, t} =
      case yn do
        "y" -> {nil, nil}
        "n" -> Github.try_auth
        _   -> init(cwd)
      end
    tu  = prompt_tracker_url
    Config.save(%__MODULE__{username: un, token: t, tracker_url: tu}, cwd)
  end

  defunp prompt_tracker_url :: nil | String.t do
    tracker_url = IO.gets "(Optional) Enter issue tracker url (e.g. https://github.com/YuMatsuzawa/ex_ghpr/issues): "
    case String.rstrip(tracker_url, ?\n) do
      ""  -> nil
      url ->
        case validate_tracker_url(url) do
          {:error, :trailing_slash} -> IO.puts("Must not end with slash.") && prompt_tracker_url
          {:error, _invalid_url   } -> IO.puts("Invalid URL.") && prompt_tracker_url
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
  alias Croma.Result, as: R
  alias ExGHPR.GlobalConfig, as: GConf
  alias ExGHPR.LocalConfig, as: LConf
  alias ExGHPR.LocalGitRepositoryPath, as: LPath

  @cmd_name    Mix.Project.config[:escript][:name]
  @cmd_version Mix.Project.config[:version]
  @config_file Path.join(["~", ".config", @cmd_name])

  @username_pattern ~r/\A\n\Z/

  def cmd_name,    do: @cmd_name
  def cmd_version, do: @cmd_version

  defun init :: R.t(map) do
    IO.puts "#{cmd_name} - #{cmd_version}"
    {:ok, _conf} = GConf.init
    LConf.init(File.cwd!)
  end

  defun load :: R.t(map) do
    File.read(Path.expand(@config_file)) # expand runtime to support precompiled binary
    |> R.bind(&Poison.decode/1)
  end

  defun ensure_cwd(cwd :: Path.t) :: map do
    case load do
      {:error, _}                -> init |> R.get
      {:ok, %{^cwd => _} = conf} -> conf
      {:ok, _conf}               -> LConf.init(cwd) |> R.get
    end
  end

  defun save(%GConf{} = gconf) :: R.t(map) do
    current_conf = case load do
      {:error, _} -> %{}
      {:ok, conf} -> conf
    end
    new_conf = Map.put(current_conf, "global", gconf)
    case File.write(Path.expand(@config_file), Poison.encode!(new_conf)) do
      :ok -> load
      e   -> e
    end
  end
  defun save(%LConf{} = lconf, path :: v[LPath.t]) :: R.t(map) do
    {:ok, current_conf} = load
    new_conf = Map.put(current_conf, path, lconf)
    case File.write(Path.expand(@config_file), Poison.encode!(new_conf)) do
      :ok -> load
      e   -> e
    end
  end
end
