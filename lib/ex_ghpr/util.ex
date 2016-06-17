use Croma

defmodule ExGHPR.Util do
  defun puts_last_line(str :: v[String.t]) :: :ok do
    String.split(str, "\n", trim: true)
    |> Enum.reverse
    |> hd
    |> IO.puts
  end
end
