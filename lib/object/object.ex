defmodule Object do
  defstruct hash: nil,
            type: :undefined,
            size: nil,
            data: nil

  def new(hash, type, data, size \\ nil) do
    %__MODULE__{
      hash: hash,
      type: type,
      size: size || String.length(data),
      data: data
    }
  end

  def header_bytes(object) do
    "#{object.type} #{object.size}"
  end

  def read_object(binary) when is_binary(binary) do
    case binary |> String.split(<<0>>) do
      [header_bytes | [data_bytes | []]] ->
        {:ok, {type, size}} = read_header(header_bytes)
        {:ok, data} = read_data(data_bytes, size)
        {:ok, Object.new(binary |> Hash.apply_hash(), type, data, size)}

      _ ->
        {:error, "object has invalid format"}
    end
  end

  def read_header(header) when is_binary(header) do
    case header |> String.split(" ") do
      [type | [size | []]] -> {:ok, {type |> String.to_atom(), size |> String.to_integer()}}
      _ -> {:error, "invalid format for header"}
    end
  end

  def read_data(data, expected_size) when is_binary(data) do
    if data |> String.length() == expected_size do
      {:ok, data}
    else
      {:error, "data size does not match declared size"}
    end
  end
end
