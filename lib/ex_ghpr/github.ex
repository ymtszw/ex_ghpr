use Croma

defmodule ExGHPR.Github do
  alias ExGHPR.Util
  alias Croma.Result, as: R
  alias HTTPoison.Response, as: Res

  @github_api_host "https://api.github.com"

  # Auth related

  defun prompt_username() :: String.t do
    Util.prompt_until_pattern_match("Enter your Github username: ", ~r/\A\S+\n\Z/)
  end

  @doc """
  Try authenticate to Github. Prompts for username and password. On success, returns `{username, token}`,
  where `token` is ["personal access token"](https://github.com/blog/1509-personal-api-tokens) for the user.
  This token has `repo` access scope, which allows read/write to any repository visible to the user.
  The user can always revoke the token from [Github web console](https://github.com/settings/tokens).
  """
  defun try_auth(username :: v[String.t]) :: String.t do
    password = Util.prompt_until_pattern_match("Enter your password for #{username}: ", ~r/\A[^\n]+\n\Z/)
    IO.puts "Authenticating..."
    case acquire_access_token(username, password) do
      {:ok   , token        } -> IO.puts("OK!")                                         && token
      {:error, :unauthorized} -> IO.puts("Username/Password doesn't match. Try again.") && try_auth(username)
      {:error, other        } -> raise "#{inspect(other)}"
    end
  end

  defunp acquire_access_token(username :: v[String.t], password :: v[String.t]) :: R.t(String.t) do
    {:ok, hostname} = :inet.gethostname
    body = %{
      scopes: "repo",
      note:   "#{ExGHPR.Config.cmd_name} for #{username}@#{hostname}"
    }
    headers = %{
      "authorization" => "Basic #{Base.encode64("#{username}:#{password}")}",
      "content-type"  => "application/json",
    }
    case HTTPoison.post("#{@github_api_host}/authorizations", Poison.encode!(body), headers) do
      {:ok, %Res{status_code: 201, body: raw_body}} ->
        Poison.decode(raw_body)
        |> R.map(fn body -> body["token"] end)
      {:ok, %Res{status_code: 401}                } -> {:error, :unauthorized}
      {:ok, %Res{status_code: c, body: raw_body}  } -> {:error, [status_code: c, body: Poison.decode!(raw_body)]}
    end
  end

  # Create/List related

  defun pull_request_api_url(%Git.Repository{} = repo, remote :: v[String.t]) :: R.t(String.t) do
    Util.fetch_remote_owner_repo(repo, remote)
    |> R.map(fn o_r -> "#{@github_api_host}/repos/#{o_r}/pulls" end)
  end

  @doc """
  Returns `Croma.Result.t(html_url)` where `html_url` is resultant PR link `String`.
  """
  defun create_pull_request(pr_url   :: v[String.t],
                            username :: v[String.t],
                            token    :: v[String.t],
                            title    :: v[String.t],
                            head     :: v[String.t],
                            base     :: v[String.t],
                            body     :: v[String.t]) :: R.t(String.t) do
    body = %{title: title, head: head, base: base, body: body}
    headers = auth_json_headers(username, token)
    case HTTPoison.post(pr_url, Poison.encode!(body), headers) do
      {:ok, %Res{status_code: 201, body: body}} ->
        Poison.decode(body)
        |> R.map(fn pr -> pr["html_url"] end)
      {:ok, %Res{status_code: c, body: body}  } -> {:error, [status_code: c, body: Poison.decode!(body)]}
    end
  end

  @doc """
  Check existence of Pull Request for `base` from `head`.
  Returns `Croma.Result(nil | html_url)`, where `nil` indicates no Pull Request open for the branch.
  """
  defun existing_pull_request(pr_url   :: v[String.t],
                              username :: v[String.t],
                              token    :: v[String.t],
                              head     :: v[String.t],
                              base     :: v[String.t]) :: R.t(nil | String.t) do
    case HTTPoison.get(pr_url, auth_header(username, token)) do
      {:ok, %Res{status_code: 200, body: "[]"}} -> {:ok, nil}
      {:ok, %Res{status_code: 200, body: list}} ->
        Poison.decode(list)
        |> R.map(&extract_matching_pull_request_url(&1, head, base))
      {:ok, %Res{status_code: c, body: body}  } -> {:error, [status_code: c, body: Poison.decode!(body)]}
    end
  end

  defp extract_matching_pull_request_url(list, head, base) do
    branch_name = Regex.replace(~r|^\S+:|, head, "")
    matched = Enum.find(list, fn pr ->
      pr["head"]["ref"] == branch_name && pr["base"]["ref"] == base
    end)
    case matched do
      nil -> nil
      map -> map["html_url"]
    end
  end

  # Search related

  @doc """
  Returns list of PR in Croma.Result
  """
  defun search_pull_requests_with_sha_hash(owner_repo :: v[String.t], username :: v[String.t], token :: v[String.t], sha_hash :: v[String.t]) :: R.t([map]) do
    pr_search_url = "#{@github_api_host}/search/issues"
    query = "type:pr repo:#{owner_repo} #{sha_hash}"
    case HTTPoison.get(pr_search_url, auth_header(username, token), [params: [q: query]]) do
      {:ok, %Res{status_code: 200, body: list}} -> {:ok, Poison.decode!(list) |> Map.get("items")}
      {:ok, %Res{status_code: c,   body: body}} -> {:error, [status_code: c, body: Poison.decode!(body)]}
    end
  end

  # Helpers

  def auth_json_headers(username, token) do
    Map.merge(auth_header(username, token), %{"content-type"  => "application/json"})
  end

  def auth_header(username, token), do: %{"authorization" => "Basic #{Base.encode64("#{username}:#{token}")}"}
end
