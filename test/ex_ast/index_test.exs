defmodule ExAST.IndexTest do
  use ExUnit.Case, async: true

  import ExAST.Query

  alias ExAST.Index
  alias ExAST.Index.Terms

  test "extracts structural source and pattern terms" do
    ast = Code.string_to_quoted!("Repo.transaction(fn -> :ok end)")

    assert MapSet.member?(Terms.from_source(ast), "call.remote:Repo.transaction/1")
    assert MapSet.member?(Terms.from_pattern("def run(arg) do ... end"), "def:run/1")
  end

  test "plans selector terms without low-signal generic call terms as required terms" do
    plan =
      from("def _ do ... end")
      |> where(contains("Repo.transaction(_)"))
      |> Index.plan()

    assert MapSet.member?(plan.required_terms, "call.remote:Repo.transaction/1")
    refute MapSet.member?(plan.required_terms, "node:call")
  end

  test "plans negative and any predicate candidate terms" do
    plan =
      from("def _ do ... end")
      |> where(contains("Repo.transaction(_)"))
      |> where(not contains("IO.inspect(_)"))
      |> where(contains("Map.get(_, _)") or contains("Map.fetch(_, _)"))
      |> Index.plan()

    assert MapSet.member?(plan.required_terms, "call.remote:Repo.transaction/1")
    assert MapSet.member?(plan.negative_terms, "call.remote:IO.inspect/1")
    assert Enum.any?(plan.candidate_groups, &MapSet.member?(&1, "call.remote:Map.get/2"))
    assert Enum.any?(plan.candidate_groups, &MapSet.member?(&1, "call.remote:Map.fetch/2"))
  end

  test "detects selectors that require comments and source" do
    plan =
      from("def _ do ... end")
      |> where(comment_before("public API"))
      |> Index.plan()

    assert plan.requires_comments?
    assert plan.requires_source?
  end

  test "infers same-argument terms from equality capture guards" do
    plan =
      from("left == right")
      |> where(^left == ^right)
      |> Index.plan()

    assert MapSet.member?(plan.required_terms, "call.local.same_args:==/2")
  end
end
