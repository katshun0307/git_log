defmodule Commit do
  require Logger

  defstruct hash: nil,
            size: nil,
            tree: nil,
            parents: [],
            author: nil,
            committer: nil,
            message: nil

  def set_entry(commit, key, value) do
    commit |> Map.put(key, value)
  end

  def string(c) do
    """
    Commit    #{c.hash |> Hash.encode_hash()}
    Tree      #{c.tree |> Hash.encode_hash()}
    Author    #{c.author |> Commit.Sign.to_string()}
    Committer #{c.committer |> Commit.Sign.to_string()}
    #{c.parents |> Enum.map(fn p -> "Parent     " <> (p |> Hash.encode_hash()) end) |> Enum.join("\n")}
    #{c.message}
    """
  end

  # transform object into a commit
  def new(%Object{} = object) when object.type == :commit do
    object_data_list = object.data |> String.split("\n")
    entries = object_data_list |> Enum.slice(0..-3)
    message = object_data_list |> Enum.at(-2)

    commit = %__MODULE__{
      size: object.size,
      message: message,
      hash: object.hash
    }

    Enum.reduce(
      entries,
      commit,
      &read_line/2
    )
  end

  def read_line(line, commit) do
    [entry | value_list] = line |> String.split(" ")

    case {entry, value_list |> Enum.join(" ")} do
      {"tree", tree_hash} ->
        commit |> Commit.set_entry(:tree, tree_hash |> Hash.read_hash())

      {"parent", parent_hash} ->
        commit
        |> Commit.set_entry(
          :parents,
          [parent_hash |> Hash.read_hash() | commit.parents]
        )

      {"author", data} ->
        commit |> Commit.set_entry(:author, data |> Commit.Sign.from_string())

      {"committer", data} ->
        commit |> Commit.set_entry(:committer, data |> Commit.Sign.from_string())

      {"message", data} ->
        commit |> Commit.set_entry(:message, data)

      _ ->
        commit
    end
  end

  defmodule Sign do
    defstruct [:name, :email, :timestamp]

    def to_string(s) do
      "#{s.name} #{s.email} #{s.timestamp |> DateTime.to_string()}"
    end

    def from_string(s) do
      case s |> String.split(" ") do
        [name | [email | [timestamp | _timezone]]] ->
          %Sign{
            name: name,
            email: email,
            timestamp: timestamp |> String.to_integer() |> timestamp_to_datetime()
          }

        _ ->
          {:error, "could not read sign (#{s})"}
      end
    end

    defp timestamp_to_datetime(timestamp) do
      {:ok, epoch, _} = DateTime.from_iso8601("1970-01-01T00:00:00Z")
      epoch |> DateTime.add(timestamp, :second)
    end
  end
end
