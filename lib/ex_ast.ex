defmodule ExAst do
  @moduledoc """
  Search and replace Elixir code by AST pattern.

  Patterns are valid Elixir syntax:
  - Variables (`name`, `expr`) capture matched nodes
  - `_` and `_name` are wildcards
  - Structs/maps match partially
  - Everything else matches literally

  ## Examples

      # Find all IO.inspect calls
      ExAst.search("lib/**/*.ex", "IO.inspect(_)")

      # Replace dbg with the expression itself
      ExAst.replace("lib/**/*.ex", "dbg(expr)", "expr")
  """

  alias ExAst.Patcher

  @type match :: %{
          file: String.t(),
          line: pos_integer(),
          source: String.t(),
          captures: ExAst.Pattern.captures()
        }

  @doc """
  Searches files for AST pattern matches.

  Returns a list of match maps with `:file`, `:line`, `:source`, and `:captures`.
  """
  @spec search(String.t() | [String.t()], String.t()) :: [match()]
  def search(paths, pattern) do
    paths
    |> resolve_paths()
    |> Enum.flat_map(&search_file(&1, pattern))
  end

  @doc """
  Replaces AST pattern matches in files.

  Options:
  - `:dry_run` — return changes without writing (default: `false`)

  Returns a list of `{file, count}` tuples for modified files.
  """
  @spec replace(String.t() | [String.t()], String.t(), String.t(), keyword()) :: [
          {String.t(), pos_integer()}
        ]
  def replace(paths, pattern, replacement, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)

    paths
    |> resolve_paths()
    |> Enum.flat_map(&replace_file(&1, pattern, replacement, dry_run))
  end

  defp search_file(file, pattern) do
    source = File.read!(file)

    Patcher.find_all(source, pattern)
    |> Enum.map(fn %{range: range, node: node, captures: captures} ->
      %{
        file: file,
        line: range.start[:line],
        source: Sourceror.to_string(node),
        captures: captures
      }
    end)
  end

  defp replace_file(file, pattern, replacement, dry_run) do
    source = File.read!(file)
    matches = Patcher.find_all(source, pattern)

    if matches == [] do
      []
    else
      result = Patcher.replace_all(source, pattern, replacement)
      unless dry_run, do: File.write!(file, result)
      [{file, length(matches)}]
    end
  end

  defp resolve_paths(paths) when is_list(paths), do: Enum.flat_map(paths, &resolve_paths/1)

  defp resolve_paths(glob) when is_binary(glob) do
    cond do
      String.contains?(glob, "*") -> Path.wildcard(glob)
      File.dir?(glob) -> Path.wildcard(Path.join(glob, "**/*.ex"))
      true -> [glob]
    end
    |> Enum.filter(&String.ends_with?(&1, ".ex"))
  end
end
