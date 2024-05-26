defmodule Autobuild.Parser do
  def pull_tags(source_lines) do
    source_lines
    |> Enum.filter(&String.starts_with?(&1, "# Tag:"))
    |> Enum.flat_map(&String.split(&1, "# Tag:"))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn line -> String.length(line) == 0 end)
  end

  def purge_imports(import_lines, source_lines) do
    tags = pull_tags(source_lines)

    if Enum.empty?(tags) do
      import_lines
    end

    Enum.filter(import_lines, fn line ->
      trimmed = String.trim(line)

      case Enum.any?(tags, fn tag -> String.contains?(trimmed, tag) end) do
        true ->
          false

        false ->
          true
      end
    end)
  end

  @doc """
  Dedupe imports in a list of imports
  """
  def dedupe_imports(lines_of_code) do
    Enum.reduce(lines_of_code, %{}, fn line, acc ->
      trimmed = String.trim(line)

      case trimmed do
        <<f, r, o, m, _, rest::binary>> when <<f, r, o, m>> == "from" ->
          [mod, _ | imports] = String.split(rest, " ")
          import_list = String.split(hd(imports), ",") |> Enum.map(&String.trim(&1))

          case Map.get(acc, mod) do
            nil ->
              Map.put(acc, mod, import_list)

            _ ->
              Map.update(acc, mod, import_list, fn imports ->
                imports ++ import_list
              end)
          end

        <<i, m, p, o, r, t, _, rest::binary>> when <<i, m, p, o, r, t>> == "import" ->
          mod = String.split(rest, ",") |> Enum.map(&String.trim(&1))

          Map.put(acc, hd(mod), [])
      end
    end)
    |> Enum.reduce([], fn {mod, imports}, acc ->
      case imports do
        [] ->
          ["import " <> mod <> "\n" | acc]

        _ ->
          sorted = Enum.sort(imports) |> Enum.join(", ")
          [
            "from " <> mod <> " import (" <> sorted <> ")\n"
            | acc
          ]
      end
    end)
    |> Enum.sort()
  end

  def hoist_imports(lines_of_code) do
    output =
      Enum.reduce(
        lines_of_code,
        {[], [], []},
        fn line, acc ->
          {imports, current_import, stack} = acc

          case line do
            <<i, m, p, o, r, t, rest::binary>>
            when <<i, m, p, o, r, t>> == "import" ->
              {["import " <> String.trim(rest)] ++ imports, [], []}

            <<f, r, o, m, rest::binary>>
            when <<f, r, o, m>> == "from" ->
              trimmed = String.trim(rest)

              cond do
                has_opening_paren?(trimmed) and has_closing_paren?(trimmed) ->
                  {
                    ["from " <> trimmed] ++ imports,
                    [],
                    []
                  }

                has_opening_paren?(trimmed) ->
                  cleaned = trimmed |> String.replace("(", "") |> String.trim()

                  {
                    imports,
                    ["from" <> "\s" <> cleaned],
                    ["(" | stack]
                  }

                has_closing_paren?(trimmed) and tl(stack) == "(" ->
                  new_import = format_multi_import_statement(trimmed, acc)

                  {
                    new_import ++ imports,
                    [],
                    []
                  }

                has_closing_paren?(trimmed) ->
                  raise "Found closing paren without opening paren"

                true ->
                  {["from " <> trimmed] ++ imports, [], []}
              end

            element when current_import != [] ->
              trimmed = String.trim(element) |> String.replace(",", "")

              cond do
                has_closing_paren?(trimmed) ->
                  new_import = format_multi_import_statement(trimmed, acc)

                  {
                    [new_import] ++ imports,
                    [],
                    []
                  }

                true ->
                  {imports, current_import, [trimmed | stack]}
              end

            _ ->
              raise RuntimeError,
                message:
                  "Should not have gotten here. " <>
                    "There is probably a bug in the python source code or some import statement grammar we are not parsing correctly."
          end
        end
      )

    output
    |> elem(0)
    |> Enum.reverse()
    |> Enum.sort()
    |> Enum.uniq()
    |> Enum.map(fn line -> line <> "\n" end)
  end

  def readlines(stream) do
    output =
      Enum.reduce(stream, {:none, [], []}, fn line, acc ->
        {status, imports, source_code} = acc

        case line do
          <<i, m, p, o, r, t, rest::binary>>
          when <<i, m, p, o, r, t>> == "import" ->
            cond do
              String.trim(rest) |> String.ends_with?("(") ->
                {:multiline_import, ["import" <> rest | imports], source_code}

              String.ends_with?(rest, "\n") ->
                {:none, ["import" <> rest | imports], source_code}
            end

          <<f, r, o, m, rest::binary>>
          when <<f, r, o, m>> == "from" ->
            cond do
              String.trim(rest) |> String.ends_with?("(") ->
                {:multiline_import, ["from" <> rest | imports], source_code}

              String.ends_with?(rest, "\n") ->
                {:none, ["from" <> rest | imports], source_code}
            end

          _ ->
            cond do
              status == :multiline_import ->
                if String.trim(line) |> String.ends_with?(")") do
                  {:none, [line | imports], source_code}
                else
                  {:multiline_import, [line | imports], source_code}
                end

              true ->
                {:none, imports, [line | source_code]}
            end
        end
      end)

    case output do
      {:none, imports, source_code} ->
        {:ok, Enum.reverse(imports), Enum.reverse(source_code)}

      _ ->
        raise "Oh shit"
    end
  end

  defp has_opening_paren?(str), do: String.contains?(str, "(")
  defp has_closing_paren?(str), do: String.contains?(str, ")")

  defp format_multi_import_statement(trimmed, acc) do
    {_imports, current_import, stack} = acc

    cleaned = trimmed |> String.replace(")", "") |> String.trim()
    elements = Enum.take_while(stack, fn c -> c != "(" end)

    all_elements =
      Enum.filter(
        [cleaned] ++ elements,
        fn e -> e != "" end
      )
      |> Enum.reverse()

    hd(current_import) <> "\s(" <> Enum.join(all_elements, ", ") <> ")"
  end
end
