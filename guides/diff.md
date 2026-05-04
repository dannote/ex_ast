# Diff

Syntax-aware diff between Elixir source strings or files.

Unlike text-based diffs, ExAST understands Elixir structure — functions are
matched by name and arity, reorders are reported as moves, and changes are
classified by kind.

## Usage

```elixir
result = ExAST.diff(old_source, new_source)
result.edits
#=> [%ExAST.Diff.Edit{op: :update, kind: :function, summary: "updated def first/0", ...}]

# Or diff files directly
result = ExAST.diff_files("lib/old.ex", "lib/new.ex")

# Apply the diff to produce patched source
ExAST.apply_diff(result)
```

## What it detects

| Kind | What changes |
|------|-------------|
| `:function` | Function body or guard changes |
| `:call` | Local call changes |
| `:remote_call` | Remote call changes (Module.function) |
| `:map` | Map literal changes |
| `:struct` | Struct changes |
| `:keyword` | Keyword list changes |
| `:assignment` | Assignment changes |
| `:module` | Module-level changes |

Operations: `:insert`, `:delete`, `:update`, `:move`.

## Options

```elixir
# Disable move detection
ExAST.diff(old_source, new_source, include_moves: false)
```

## How it works

1. Both sources are parsed into annotated trees with stable node IDs
2. **Anchor phase** — functions matched by `{name, arity}`, containers mapped transitively
3. **Semantic matching** — unmatched nodes scored by kind, label, and subtree similarity
4. **Child recovery** — keyed children matched by key, ordered children by compatibility
5. **Classification** — content changes → `:update`, unmatched left → `:delete`, unmatched right → `:insert`, reorder → `:move`

The algorithm is inspired by [GumTree](https://github.com/GumTreeDiff/gumtree), adapted for Elixir's AST shape.

## Limitations

- Macros are not expanded — diff is structural, not semantic
- Moves are only detected for functions within the same module body

## CLI

```bash
mix ex_ast.diff lib/old.ex lib/new.ex
mix ex_ast.diff --summary lib/old.ex lib/new.ex
mix ex_ast.diff --json lib/old.ex lib/new.ex
```
