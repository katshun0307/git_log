defmodule Client do
  alias Object

  defstruct object_dir: nil

  def new(path) do
    case find_git_root(path) do
      {:ok, root} -> %__MODULE__{object_dir: Path.join([root, ".git", "objects"])}
      {:error, reason} -> {:error, reason}
    end
  end

  defp find_git_root(path) do
    path = Path.absname(path)

    if exists_git_dir(path) do
      {:ok, path}
    else
      maybe_search_parent_dir(path)
    end
  end

  defp exists_git_dir(path) do
    dirs = path |> Path.join(".git") |> Path.wildcard()
    not (dirs == [])
  end

  defp maybe_search_parent_dir(path) do
    if path == "/" do
      {:error, "git directory not found"}
    else
      path |> Path.dirname() |> find_git_root()
    end
  end

  @doc """
  get object from hash
  """
  def get_object(client, hash) do
    hash_string = Hash.encode_hash(hash)

    object_path =
      client.object_dir
      |> Path.join(hash_string |> String.slice(0..1))
      |> Path.join(hash_string |> String.slice(2..-1))

    case File.read(object_path) do
      {:ok, contents} -> contents |> :zlib.uncompress() |> Object.read_object()
      {:error, _} -> {:error, "could not find object file (#{object_path})"}
    end
  end

  @doc """
  Apply [walk_func] to all ancestors from the commit with the specified [hash]
  """
  def walk_history(client, hash, walk_func, queue \\ [], visited \\ MapSet.new()) do
    if MapSet.member?(visited, hash) do
      maybe_advance_walk(client, walk_func, queue, visited)
    else
      {:ok, object} = get_object(client, hash)
      commit = object |> Commit.new()
      walk_func.(commit)
      new_queue = queue ++ commit.parents
      new_visited = MapSet.put(visited, hash)
      maybe_advance_walk(client, walk_func, new_queue, new_visited)
    end
  end

  def maybe_advance_walk(_client, _walk_func, [] = _queue, _visited) do
    nil
  end

  def maybe_advance_walk(client, walk_func, [queue_head | queue_rest], visited) do
    walk_history(client, queue_head, walk_func, queue_rest, visited)
  end
end
