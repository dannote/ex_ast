defmodule ExAST.Sigil do
  @moduledoc """
  Provides the `~p` sigil for compile-time pattern parsing.

      import ExAST.Sigil

      ~p"IO.inspect(expr, ...)"
      ~p"def foo(_) do ... end"
      ~p"{:ok, result}"

  The sigil parses the pattern string at compile time into an AST,
  avoiding runtime parsing overhead. The result can be passed to
  any function that accepts a pattern.
  """

  @doc """
  Parses a pattern string into AST at compile time.

  ## Examples

      iex> import ExAST.Sigil
      iex> ~p"IO.inspect(_)"
      {{:., [line: 1], [{:__aliases__, [line: 1], [:IO]}, :inspect]}, [line: 1], [{:_, [line: 1], nil}]}
  """
  defmacro sigil_p({:<<>>, _, [string]}, _modifiers) when is_binary(string) do
    pattern = Code.string_to_quoted!(string)
    Macro.escape(pattern)
  end
end
