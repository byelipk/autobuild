defmodule Autobuild.Filereader do
  def read_file(abs_path, tag) do
    safe_to_proceed =
      if File.exists?(abs_path) do
        {:ok, abs_path}
      else
        {:error, "File does not exist: " <> abs_path}
      end

    case safe_to_proceed do
      {:ok, abs_path} ->
        IO.puts(:stdio, "Reading file: " <> abs_path)

        contents =
          File.stream!(abs_path, :line)
          |> readlines()

        {_, imports, source_code} = contents

        {:ok, abs_path, imports, source_code, tag}

      {:error, reason} ->
        IO.puts(:stderr, reason)
        {:error, reason}
    end
  end

  defp readlines(stream) do
    Autobuild.Parser.readlines(stream)
  end
end
