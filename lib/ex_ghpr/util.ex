use Croma

defmodule ExGHPR.Util do
  @moduledoc false

  defun fetch_current_branch(%Git.Repository{} = repo) :: String.t do
    case Git.rev_parse(repo, ~w(--abbrev-ref HEAD)) do
      {:ok, "HEAD\n"} -> exit_with_error("Cannot open PR from detached HEAD")
      {:ok, name    } -> String.rstrip(name, ?\n)
    end
  end

  defun choose_credentials(%{"username" => lun, "token" => lt}, %{"username" => gun, "token" => gt}) :: {String.t, String.t} do
    case {lun, lt} do
      {nil, _} -> {gun, gt}
      creds    -> creds
    end
  end

  defun puts_last_line(str :: v[String.t]) :: :ok do
    String.split(str, "\n", trim: true)
    |> Enum.reverse
    |> hd
    |> IO.puts
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
