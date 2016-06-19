use Croma

defmodule ExGHPR.CLI.Create do
  @moduledoc false

  alias Croma.Result, as: R
  alias ExGHPR.Github
  import ExGHPR.{Util, CLI}

  @ssh_url_pattern ~r|:(?<owner_repo>\S+/\S+.git)\n?\Z|

  defun ensure_current_branch_pushed_to_origin(
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
        "https://#{username}:#{token}@github.com#{String.rstrip(path, ?\n)}"
      _ssh_url -> ssh_to_https(origin_url, username, token)
    end
    Git.push(repo, [origin_url_with_auth, current_branch])
  end

  defunp ssh_to_https(ssh_url :: v[String.t], username :: v[String.t], token :: v[String.t]) :: String.t do
    case Regex.named_captures(@ssh_url_pattern, ssh_url) do
      %{"owner_repo" => o_r} -> "https://#{username}:#{token}@github.com/#{String.rstrip(o_r, ?\n)}"
      nil                   -> exit_with_error("Remote URL does not match with `git@github.com:<owner>/<repo>.git`!")
    end
  end

  defun ensure_pull_requested(
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

  defp   calc_body(_branch_name, nil), do: ""
  defunp calc_body(branch_name :: v[String.t], tracker_url) :: String.t do
    case Regex.named_captures(~r/\A(?<issue_num>\d+)_/, branch_name) do
      %{"issue_num" => num} -> open_issue_url("#{tracker_url}/#{num}")
      nil                   -> ""
    end
  end
end
