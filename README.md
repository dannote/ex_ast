# ExAST 🔬

Search, replace, and diff Elixir code by AST pattern.

Patterns are plain Elixir — variables capture, `_` is a wildcard,
structs match partially, pipes are normalized. No regex, no custom DSL.

```bash
mix ex_ast.search  'IO.inspect(_)'
mix ex_ast.replace 'IO.inspect(expr, _)' 'Logger.debug(inspect(expr))' lib/
mix ex_ast.diff lib/old.ex lib/new.ex
```

## Why

Regex can't tell `IO.inspect(data)` from `IO.inspect(data, label: "debug")`.
Text diff doesn't know a function moved vs changed. ExAST works on the AST —
patterns match structure, not strings.

## Quick examples

```elixir
# Negative literals — flag potential bugs
ExAST.Patcher.find_all(source, "Enum.take(_, -_)")

# Always-true comparisons
ExAST.Patcher.find_all(source, "{a, a}")

# Compile-time config reads
ExAST.Patcher.find_all(source, "@name Application.get_env(_, _)")

# Specific atom values
import ExAST.Query
from("def handle_event(event, _, _) do ... end")
|> where(^event == :click or ^event == :keydown)

# Functions with transaction but no debug output
from("def _ do ... end")
|> where(contains("Repo.transaction(_)"))
|> where(not contains("IO.inspect(...)"))
```

## Installation

```elixir
def deps do
  [{:ex_ast, "~> 0.9", only: [:dev, :test], runtime: false}]
end
```

## Documentation

| Guide | Content |
|-------|---------|
| [Getting Started](https://hexdocs.pm/ex_ast/getting-started.html) | Install, first search, first replace |
| [Pattern Language](https://hexdocs.pm/ex_ast/pattern-language.html) | Syntax, wildcards, captures, ellipsis, pipes, recipes |
| [Querying](https://hexdocs.pm/ex_ast/querying.html) | Relationship filters, selectors, capture guards |
| [CLI Reference](https://hexdocs.pm/ex_ast/cli.html) | Command-line flags and usage |
| [Diff](https://hexdocs.pm/ex_ast/diff.html) | Syntax-aware code diffing |
| [API Reference](https://hexdocs.pm/ex_ast/api-reference.html) | Module documentation |

## What you can match

```elixir
# Function calls (any arity with ...)
Enum.map(_, _)
Logger.info(...)

# Definitions
def handle_call(msg, _, state) do _ end

# Pipes (matches both forms)
Enum.map(data, f)           # also matches: data |> Enum.map(f)

# Multi-node sequences
a = Repo.get!(_, _); Repo.delete(a)

# Tuples, structs, maps
{:ok, result}
%User{role: :admin}
%{name: name}

# Directives and attributes
use GenServer
@env Application.get_env(_, _)

# Control flow
case _ do _ -> _ end
fn _ -> _ end
```

## Limitations

- No function-name wildcards — `def _(_)` won't match arbitrary names
- Alias expansion is syntax-aware, not semantic — no macro expansion
- Multi-node patterns require contiguous statements
- Replacement formatting uses `Macro.to_string/1` — run `mix format` after

## License

[MIT](LICENSE)
