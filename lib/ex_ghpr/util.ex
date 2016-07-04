use Croma

defmodule ExGHPR.Util do
  @moduledoc false

  @remote_url_pattern ~r|[/:](?<owner_repo>[^/]+/[^/]+)\.git|

  defun prompt_until_pattern_match(message :: String.t, pattern :: Regex.t) :: String.t do
    stdin = IO.gets(message)
    if stdin =~ pattern, do: String.rstrip(stdin, ?\n), else: prompt_until_pattern_match(message, pattern)
  end

  defun fetch_current_branch(%Git.Repository{} = repo) :: String.t do
    case Git.rev_parse(repo, ~w(--abbrev-ref HEAD)) do
      {:ok, "HEAD\n"} -> exit_with_error("Cannot open PR from detached HEAD")
      {:ok, name    } -> String.rstrip(name, ?\n)
    end
  end

  defun fetch_remote_owner_repo(%Git.Repository{} = repo, remote :: v[String.t]) :: Croma.Result.t(String.t) do
    Git.ls_remote(repo, ["--get-url", remote])
    |> Croma.Result.map(fn remote_url ->
      Regex.named_captures(@remote_url_pattern, remote_url) # Should rarely fail
      |> Map.get("owner_repo")
    end)
  end

  defun puts_last_line(str :: v[String.t]) :: :ok do
    String.split(str, "\n", trim: true)
    |> Enum.reverse
    |> hd
    |> IO.puts
  end

  def   open_url(""), do: ""
  defun open_url(url :: v[String.t]) :: String.t do
    open_cmd =
      System.find_executable("open") ||                 # OSX
      (System.find_executable("cmd") && "cmd /c start") # Windows
    if open_cmd, do: :os.cmd('#{open_cmd} #{url}')
    url
  end

  defun copy_to_clipboard_and_echo(str :: v[String.t]) :: :ok do
    clip_cmd =
      System.find_executable("pbcopy") || # OSX
      System.find_executable("clip")      # Windows
    if clip_cmd do
      :os.cmd('echo #{str} | #{clip_cmd}') # echo will append newline after `str`
      "#{str} (copied to clipboard!)"
    else
      str
    end |> IO.puts
  end

  defun exit_with_error(message :: v[String.t]) :: no_return do
    IO.puts(:stderr, message)
    exit({:shutdown, 1})
  end
end
