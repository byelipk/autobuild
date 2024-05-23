defmodule Autobuild do
  def read_files(paths_and_tags) do
    Enum.map(paths_and_tags, fn {abs_path, tag} ->
      read_file(abs_path, tag)
    end)
  end

  def read_file(abs_path, tag) do
    Autobuild.Filereader.collect(abs_path, tag)
  end

  def write(dst_path, statements) do
    Autobuild.Filewriter.write(statements, dst_path)
  end

  def flatten(lines) do
    Autobuild.Parser.flatten(lines)
  end

  def parse(stream) do
    Autobuild.Parser.parse(stream)
  end
end
