defmodule Hash do
  @doc """
  Apply hash to data
  """
  def apply_hash(data) do
    :crypto.hash(:sha, data)
  end

  @doc """
  Transform hash binary into hex encoded string
  """
  def encode_hash(binary) do
    binary |> Base.encode16() |> String.downcase()
  end

  @doc """
  Read hash from hex encoded string
  """
  def read_hash(str) do
    str |> String.upcase() |> Base.decode16!()
  end
end
