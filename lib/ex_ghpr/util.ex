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

  defun exit_with_error(message :: v[String.t]) :: no_return do
    IO.puts(:stderr, message)
    exit({:shutdown, 1})
  end
end
