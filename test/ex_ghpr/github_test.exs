defmodule ExGHPR.GithubTest do
  use Croma.TestCase

  test "pull_request_api_url/2 should build API URL for whatever remote" do
    local_repo = %Git.Repository{path: File.cwd!} # Local ex_ghpr root directory, which should be valid git repository
    remote_owner = "test_owner"
    remote_repo  = "test_repo"
    remote_name  = "test_remote"
    [
      "git@github.com:#{remote_owner}/#{remote_repo}.git",
      "https://github.com/#{remote_owner}/#{remote_repo}.git",
      "https://SomeUserName@github.com/#{remote_owner}/#{remote_repo}.git",
    ] |> Enum.each(fn remote_url ->
      Git.remote(local_repo, ["add", remote_name, remote_url])
      assert Github.pull_request_api_url(local_repo, remote_name) == {:ok, "https://api.github.com/repos/test_owner/test_repo/pulls"}
      Git.remote(local_repo, ["remove", remote_name])
    end)
  end
end
