# Indexing and Code Intelligence

ExAST can summarize Elixir source and selectors into conservative metadata for
code intelligence systems. These APIs are useful when you want to build an
external index, database-backed search, or analyzer cache while keeping ExAST as
the final semantic verifier.

Index metadata is intentionally advisory: use it to find candidates, then verify
matches with `ExAST.Selector.find_all/3`, `ExAST.Selector.match?/3`, or
`ExAST.Patcher.find_all/3`.

## Structural index plans

`ExAST.Index.plan/1` accepts a pattern or selector and returns an
`ExAST.Index.Plan`:

```elixir
import ExAST.Query

plan =
  from("def _ do ... end")
  |> where(contains("Repo.transaction(_)"))
  |> where(not contains("IO.inspect(...)"))
  |> ExAST.Index.plan()

plan.required_terms
#=> MapSet.new(["call.remote:Repo.transaction/1", ...])

plan.negative_terms
#=> MapSet.new(["call.remote:IO.inspect/1", ...])
```

A plan contains:

| Field | Meaning |
|-------|---------|
| `required_terms` | High-signal terms that should be present in matching source |
| `optional_terms` | Additional terms that can help rank or refine candidates |
| `negative_terms` | Terms from negated predicates |
| `candidate_groups` | Alternative candidate sets for `any` / `or` predicates |
| `requires_source?` | Matching needs source text, not only AST |
| `requires_comments?` | Matching depends on comment metadata |

Example with alternative predicates:

```elixir
plan =
  from("def _ do ... end")
  |> where(contains("Map.get(_, _)") or contains("Map.fetch(_, _)"))
  |> ExAST.Index.plan()

plan.candidate_groups
#=> [MapSet.new(["call.remote:Map.get/2"]),
#    MapSet.new(["call.remote:Map.fetch/2"])]
```

## Source and pattern terms

For lower-level indexing, use `ExAST.Index.Terms` directly:

```elixir
ast = Code.string_to_quoted!("Repo.transaction(fn -> :ok end)")

ExAST.Index.Terms.from_source("Repo.transaction(fn -> :ok end)")
#=> MapSet.new(["call.remote:Repo.transaction/1", ...])

ExAST.Index.Terms.from_ast(ast)
#=> MapSet.new(["call.remote:Repo.transaction/1", ...])

ExAST.Index.Terms.from_pattern("def run(arg) do ... end")
#=> MapSet.new(["def:run/1", ...])
```

Terms are stable strings intended for external storage. They are deliberately
conservative and do not replace verification.

## Comment-aware selectors

Selectors can report whether they need source/comments:

```elixir
selector =
  from("def _ do ... end")
  |> where(comment_before("public API"))

ExAST.Selector.requires_source?(selector)
#=> true

ExAST.Selector.requires_comments?(selector)
#=> true
```

Use this when deciding whether an index hit can be verified from AST alone or
needs original source text.

## Selector verification

`ExAST.Selector` exposes direct verification helpers:

```elixir
selector =
  from("def _ do ... end")
  |> where(contains("Repo.transaction(_)"))

ExAST.Selector.find_all(source, selector)
ExAST.Selector.match?(source, selector)
```

These functions accept the same kinds of input as `ExAST.Patcher.find_all/3`:
source strings, ASTs, and Sourceror zippers.

## Comments

Use `ExAST.Comments` to extract comment text and position metadata:

```elixir
comments = ExAST.Comments.extract(source)
#=> [%ExAST.Comment{text: "# TODO", line: 12, column: 3, ...}]

ExAST.Comments.text(source)
#=> "# TODO\n# FIXME"
```

## Symbols

`ExAST.Symbols` extracts lightweight definition and reference facts from source
or AST:

```elixir
ExAST.Symbols.definitions(source)
#=> [%ExAST.Symbol.Definition{kind: :def, qualified_name: "Example.run/1", ...}]

ExAST.Symbols.references(source)
#=> [%ExAST.Symbol.Reference{kind: :remote_call, qualified_name: "Repo.transaction/1", ...}]
```

Definitions include modules, functions, macros, delegates, callbacks, and module
attributes. References include remote calls, local calls, aliases, and module
attributes.

Symbol structs expose both a stable string form and, when safely resolvable, a
BEAM-native MFA tuple:

```elixir
reference =
  ExAST.Symbols.references("Enum.map(items, & &1.id)")
  |> Enum.find(&(&1.qualified_name == "Enum.map/2"))

reference.qualified_name
#=> "Enum.map/2"

reference.mfa
#=> {Enum, :map, 2}

ExAST.Symbols.qualified_name({Enum, :map, 2})
#=> "Enum.map/2"

ExAST.Symbols.matches?(reference, "Enum.map/2")
#=> true

ExAST.Symbols.matches?(reference, {Enum, :map, 2})
#=> true
```

As with structural terms, symbol extraction is syntactic. ExAST does not perform
macro expansion, alias resolution, or type analysis. It does not create module
atoms for unknown modules; unresolved symbols keep `mfa: nil`.
