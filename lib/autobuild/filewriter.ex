defmodule Autobuild.Filewriter do
  def write(statements, filename) do
    filenames = get_filenames(statements)

    combined_imports =
      Enum.reduce(statements, [], fn
        {:ok, _filepath, imports, _}, acc ->
          acc ++ scrub_imports(imports, filenames)

        {:error, _}, acc ->
          acc
      end)

    combined_source =
      Enum.reduce(statements, [], fn
        {_, filepath, _imports, source_code}, acc ->
          preamble = "\n\n# File: " <> filepath <> "\n# ==========\n\n"
          acc ++ [preamble] ++ source_code

        {:error, _}, acc ->
          acc
      end)

    File.write!(filename, combined_imports ++ combined_source)
  end

  defp get_filenames(statements) do
    Enum.reduce(statements, [], fn {_, filepath, _, _}, acc ->
      acc ++ [filepath |> Path.basename() |> String.replace(~r/\.py/, "")]
    end)
  end

  defp scrub_imports(imports, _filenames) do
    imports
  end
end
