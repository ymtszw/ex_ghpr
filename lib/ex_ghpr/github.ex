use Croma

defmodule ExGHPR.Github do
  alias Croma.Result, as: R
  alias HTTPoison.Response, as: Res

  @github_api_host "https://api.github.com"
  @remote_url_pattern ~r|[/:](?<owner_repo>[^/]+/[^/]+)\.git|

  @doc """
  Try authenticate to Github. Prompts for username and password. On success, returns `{username, token}`,
  where `token` is ["personal access token"](https://github.com/blog/1509-personal-api-tokens) for the user.
  This token has `repo` access scope, which allows read/write to any repository visible to the user.
  The user can always revoke the token from [Github web console](https://github.com/settings/tokens).
  """
  defun try_auth :: {String.t, String.t} do
    username = prompt_until_pattern_match("Enter your Github username: ", ~r/\A\S+\n\Z/)
    password = prompt_until_pattern_match("Enter your password for #{username}: ", ~r/\A[^\n]+\n\Z/)
    IO.puts "Authenticating..."
    case acquire_access_token(username, password) do
      {:ok   , token        } -> IO.puts("OK!")                                         && {username, token}
      {:error, :unauthorized} -> IO.puts("Username/Password doesn't match. Try again.") && try_auth
      {:error, other        } -> raise "#{inspect(other)}"
    end
  end

  defunp prompt_until_pattern_match(message :: String.t, pattern :: Regex.t) :: String.t do
    stdin = IO.gets(message)
    if stdin =~ pattern, do: String.rstrip(stdin, ?\n), else: prompt_until_pattern_match(message, pattern)
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

  defun pull_request_api_url(%Git.Repository{} = repo, remote :: v[String.t]) :: R.t(String.t) do
    Git.remote(repo, ["get-url", remote])
    |> R.map(fn remote_url ->
      %{"owner_repo" => o_r} = Regex.named_captures(@remote_url_pattern, remote_url) # Should rarely fail
      "#{@github_api_host}/repos/#{o_r}/pulls"
    end)
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
  Returns `Croma.Result` of URL if exist, otherwise `nil`
  """
  defun existing_pull_request(pr_url   :: v[String.t],
                              username :: v[String.t],
                              token    :: v[String.t],
                              head     :: v[String.t],
                              base     :: v[String.t]) :: R.t(nil | String.t) do
    params = [params: [state: "open", head: head, base: base]]
    headers = auth_json_headers(username, token)
    case HTTPoison.get(pr_url, headers, params) do
      {:ok, %Res{status_code: 200, body: "[]"}} -> {:ok, nil}
      {:ok, %Res{status_code: 200, body: list}} ->
        Poison.decode(list)
        |> R.map(fn [hd | _] -> hd["html_url"] end)
      {:ok, %Res{status_code: c, body: body}  } -> {:error, [status_code: c, body: Poison.decode!(body)]}
    end
  end

  defp auth_json_headers(username, token) do
    %{
      "authorization" => "Basic #{Base.encode64("#{username}:#{token}")}",
      "content-type"  => "application/json",
    }
  end
end
