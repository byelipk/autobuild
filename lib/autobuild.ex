defmodule Autobuild do
  def build(src_dir, dist_dir) do
    IO.puts("Command received.")
    IO.puts("Source directory: #{src_dir}")
    IO.puts("Distribution directory: #{dist_dir}")
    IO.puts("")
    IO.puts("Building...")

    all_files_in_src_dir =
      File.ls!(src_dir)
      |> Enum.filter(fn file ->
        Path.extname(file) == ".py"
      end)
      |> Enum.map(fn file ->
        {Path.join([src_dir, file]), file}
      end)
      |> Enum.sort()

    IO.puts("Concatenating files...")

    combine_files(all_files_in_src_dir, dist_dir)

    sanity_check(dist_dir)

    IO.puts("Build complete.")
  end

  def combine_files(paths_and_tags, write_to) do
    read_files(paths_and_tags)
    |> write_file(write_to)
  end

  def read_files(paths_and_tags) do
    Enum.map(paths_and_tags, fn {read_from, tag} ->
      read_file(read_from, tag)
    end)
  end

  def read_file(read_from, tag) do
    Autobuild.Filereader.read_file(read_from, tag)
  end

  def write_file(statements, write_to) do
    Autobuild.Filewriter.write_file(statements, write_to)
  end

  def sanity_check(dist_dir) do
    IO.puts("Sanity check...")

    output =
      File.stream!(dist_dir, :line)
      |> Autobuild.Parser.sanity_check()

    { checks, _, _ } = output

    Enum.each(checks, fn check -> 
      message = Map.get(check, :message)
      IO.puts("Sanity check: #{message}")
      IO.inspect(Map.get(check, :data))
    end)
  end
end
