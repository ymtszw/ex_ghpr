use Croma

defmodule ExGHPR.CLI.Search do

  defun blame(%Git.Repository{} = repo, file_name :: v[String.t], line_number :: v[non_neg_integer]) :: Croma.Result.t(binary) do
    Git.blame(repo, ~w(-l -w -L #{line_number},#{line_number} #{file_name}))
    |> Croma.Result.map(&String.split/1)
    |> Croma.Result.map(&hd/1)
  end
end
