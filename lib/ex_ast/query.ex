defmodule ExAST.Query do
  import Kernel, except: [not: 1]

  @moduledoc """
  SQL-like query API for AST search.

  This module builds on `ExAST.Selector` with names that read like query
  predicates:

      import ExAST.Query

      from("def _ do ... end")
      |> where(contains("Repo.transaction(_)"))
      |> where(not contains("IO.inspect(_)"))

  The resulting query can be passed to `ExAST.search/3` or
  `ExAST.Patcher.find_all/3` anywhere a selector is accepted.
  """

  alias ExAST.Selector

  @type t :: Selector.t()

  @doc "Starts a query from one pattern or a list of alternative patterns."
  defdelegate from(pattern), to: Selector

  @doc "Adds a predicate filter without changing the selected node."
  defmacro where(query, expr) do
    quote do
      require ExAST.Selector
      ExAST.Selector.where(unquote(query), unquote(expr))
    end
  end

  @doc "Finds matching descendants of the current selection."
  defdelegate find(query, pattern), to: Selector

  @doc "Finds matching direct children of the current selection."
  defdelegate find_child(query, pattern), to: Selector

  @doc "Matches when the selected node contains a descendant matching `pattern`."
  defdelegate contains(pattern), to: Selector

  @doc "Matches when the selected node has a direct child matching `pattern`."
  defdelegate has_child(pattern), to: Selector

  @doc "Matches when the selected node is inside an ancestor matching `pattern`."
  defdelegate inside(pattern), to: Selector

  @doc "Matches when the selected node has a direct parent matching `pattern`."
  defdelegate parent(pattern), to: Selector

  @doc "Matches when a previous sibling matches `pattern`."
  defdelegate follows(pattern), to: Selector

  @doc "Matches when a following sibling matches `pattern`."
  defdelegate precedes(pattern), to: Selector

  @doc "Matches when the immediately previous sibling matches `pattern`."
  defdelegate immediately_follows(pattern), to: Selector

  @doc "Matches when the immediately following sibling matches `pattern`."
  defdelegate immediately_precedes(pattern), to: Selector

  @doc "Matches the first semantic child in its parent."
  defdelegate first(), to: Selector

  @doc "Matches the last semantic child in its parent."
  defdelegate last(), to: Selector

  @doc "Matches the nth semantic child in its parent, using 1-based indexing."
  defdelegate nth(index), to: Selector

  @doc "Matches when any nested predicate matches."
  defdelegate any(predicates), to: Selector

  @doc "Matches when all nested predicates match."
  defdelegate all(predicates), to: Selector

  @doc "Matches comments associated with the selected node."
  defdelegate comment(matcher), to: Selector

  @doc "Matches comments immediately before the selected node."
  defdelegate comment_before(matcher), to: Selector

  @doc "Matches comments immediately after the selected node."
  defdelegate comment_after(matcher), to: Selector

  @doc "Matches comments inside the selected node range."
  defdelegate comment_inside(matcher), to: Selector

  @doc "Matches inline comments on the selected node start line."
  defdelegate comment_inline(matcher), to: Selector

  @doc "Builds a substring comment matcher."
  defdelegate text(value), to: Selector
  defdelegate text(value, opts), to: Selector

  @doc "Builds an exact comment matcher."
  defdelegate exact(value), to: Selector
  defdelegate exact(value, opts), to: Selector

  @doc "Builds a comment prefix matcher."
  defdelegate prefix(value), to: Selector
  defdelegate prefix(value, opts), to: Selector

  @doc "Builds a comment suffix matcher."
  defdelegate suffix(value), to: Selector
  defdelegate suffix(value, opts), to: Selector
end
