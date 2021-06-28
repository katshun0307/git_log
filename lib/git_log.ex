defmodule GitLog do
  @moduledoc """
  Documentation for `GitLog`.
  """

  def main([hash]) do
    git_log(hash)
  end

  def main([]) do
    # TODO: get current head
    nil
  end

  defp git_log(hash) do
    client = Client.new(get_current_dir())
    Client.walk_history(client, hash |> Hash.read_hash(), &walk_func/1)
  end

  defp walk_func(commit) do
    commit |> Commit.string() |> IO.puts()
  end

  defp get_current_dir() do
    File.cwd!() |> Path.basename()
  end
end
