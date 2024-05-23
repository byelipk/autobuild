defmodule Autobuild.Filereader do
  def collect(abs_path, tag) do
    safe_to_proceed =
      if File.exists?(abs_path) do
        {:ok, abs_path}
      else
        {:error, "File does not exist: " <> abs_path}
      end

    case safe_to_proceed do
      {:ok, abs_path} ->
        contents =
          File.stream!(abs_path, :line)
          |> parse_stream()

        imports = elem(contents, 1) |> Enum.reverse()
        source_code = elem(contents, 2) |> Enum.reverse()

        {:ok, tag, imports, source_code}

      {:error, reason} ->
        IO.puts(reason)
    end
  end

  defp parse_stream(stream) do
    Autobuild.Parser.parse(stream)
  end
end
