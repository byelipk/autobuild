defmodule Autobuild.Filewriter do
  def write_file(statements, filename) do
    initial = []

    combined_source =
      Enum.reduce(statements, initial, fn
        {_, filepath, _imports, source_code, tag}, acc ->
          tag = String.replace(tag, ".py", "")

          preamble =
            [
              "\n\n",
              "# ==========\n",
              "# File: " <> filepath <> "\n",
              "# Tag: " <> tag <> "\n",
              "# ==========\n"
            ]
            |> Enum.join()

          acc ++ [preamble] ++ source_code

        {:error, _}, acc ->
          acc
      end)

    combined_imports =
      Enum.reduce(statements, [], fn
        {:ok, _filepath, imports, _source_code, _tag}, acc ->
          acc ++ imports

        {:error, _}, acc ->
          acc
      end)
      |> Autobuild.Parser.hoist_imports()
      |> Autobuild.Parser.dedupe_imports()
      |> Autobuild.Parser.purge_imports(combined_source)

    commentary = [
      "# ==========\n",
      "# This is an autogenerated file.\n",
      "# Do not modify directly. \n",
      "# ==========\n",
      "\n",
      "\n"
    ]

    File.write!(
      filename,
      commentary ++ combined_imports ++ combined_source
    )
  end
end
