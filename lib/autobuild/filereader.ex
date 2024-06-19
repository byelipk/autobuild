defmodule Autobuild.Filereader do
  def read_file(abs_path, tag) do
    case run_safety_check(abs_path) do
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

  defp run_safety_check(abs_path) do
    if File.exists?(abs_path) do
      basename = Path.basename(abs_path)

      if String.starts_with?(basename, "_") do
        {:error, "File is protected: " <> abs_path}
      else
        {:ok, abs_path}
      end
    else
      {:error, "File does not exist: " <> abs_path}
    end
  end
end
