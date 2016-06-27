use Croma

defmodule ExGHPR.CLI.Search do
  alias ExGHPR.Github

  defun blame(%Git.Repository{} = repo, file_name :: v[String.t], line_number :: v[non_neg_integer]) :: Croma.Result.t(String.t) do
    Git.blame(repo, ~w(-l -w -L #{line_number},#{line_number} #{file_name}))
    |> Croma.Result.map(&String.split/1)
    |> Croma.Result.map(&hd/1)
  end

  defun search_pull_requests_and_list_url(owner_repo :: v[String.t], u_n :: v[String.t], t :: v[String.t], sha_hash :: v[String.t]) :: Croma.Result.t([String.t]) do
    Github.search_pull_requests_with_sha_hash(owner_repo, u_n, t, sha_hash)
    |> Croma.Result.map(fn list ->
      Enum.map(list, fn pr -> pr["html_url"] end)
    end)
  end
end
