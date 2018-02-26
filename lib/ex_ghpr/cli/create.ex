use Croma

defmodule ExGHPR.CLI.Create do
  @moduledoc false

  alias ExGHPR.{Util, CLI}
  alias Croma.Result, as: R
  alias ExGHPR.Github

  defun ensure_current_branch_pushed_to_origin(%Git.Repository{} = repo, current_branch :: v[String.t]) :: R.t(term) do
    case Git.remote(repo, ["get-url", "origin"]) do
      {:error, _} ->
        Util.exit_with_error("Cannot find `origin` remote")
      {:ok, _url} ->
        # Use System.cmd/3 here in order to print intermediate stdout line-by-line.
        case System.cmd("git", ["push", "--set-upstream", "origin", current_branch], [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]) do
          {_io_stream, 0} -> {:ok, :push_success}
          {_io_stream, e} -> {:error, {:push_failure, e}}
        end
    end
  end

  defun ensure_pull_requested(opts           :: Keyword.t,
                              %Git.Repository{} = repo,
                              current_branch :: v[String.t],
                              username       :: v[String.t],
                              token          :: v[String.t],
                              tracker_url    :: nil | String.t) :: R.t(term) do
    api_url = Github.pull_request_api_url(repo, CLI.validate_remote(opts[:remote], "origin"))
    |> R.map_error(&Util.exit_with_error(inspect(&1)))
    |> R.get()
    head = case CLI.validate_fork(opts[:fork]) do
      nil  -> current_branch
      fork -> "#{fork}:#{current_branch}"
    end
    base = CLI.validate_base(opts[:base], "master")
    Github.existing_pull_request(api_url, username, token, head, base)
    |> R.bind(fn
      nil ->
        title = CLI.validate_title(opts[:title], current_branch)
        body = CLI.validate_message(opts[:message], calc_body(current_branch, tracker_url))
        Github.create_pull_request(api_url, username, token, title, head, base, body)
      url -> {:ok, url}
    end)
  end

  defp calc_body(_branch_name, nil), do: ""
  defp calc_body( branch_name, tracker_url) do
    case Regex.named_captures(~r/\A(?<issue_num>\d+)_/, branch_name) do
      %{"issue_num" => num} -> "#{tracker_url}/#{num}"
      nil                   -> ""
    end
  end
end
