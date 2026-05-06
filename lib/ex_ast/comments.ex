defmodule ExAST.Comments do
  @moduledoc """
  Extracts comments from Elixir source while preserving source positions.
  """

  alias ExAST.Comment

  @spec extract(String.t()) :: [Comment.t()]
  def extract(source) when is_binary(source) do
    {_ast, comments} = Code.string_to_quoted_with_comments!(source)

    Enum.map(comments, fn comment ->
      %Comment{
        text: Map.get(comment, :text, ""),
        line: Map.get(comment, :line),
        column: Map.get(comment, :column),
        previous_eol_count: Map.get(comment, :previous_eol_count),
        next_eol_count: Map.get(comment, :next_eol_count)
      }
    end)
  end

  @spec text(String.t()) :: String.t()
  def text(source) when is_binary(source) do
    source
    |> extract()
    |> Enum.map_join("\n", & &1.text)
  end
end
