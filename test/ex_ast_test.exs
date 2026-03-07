defmodule ExASTTest do
  use ExUnit.Case, async: true

  describe "search/2" do
    @tag :tmp_dir
    test "finds matches across files", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "a.ex"), """
      IO.inspect(x)
      IO.puts("hello")
      """)

      File.write!(Path.join(dir, "b.ex"), """
      IO.inspect(y, label: "debug")
      """)

      results = ExAST.search(dir, "IO.inspect(_)")
      assert length(results) == 1
      assert [%{file: _, line: 1, source: _, captures: _}] = results

      results = ExAST.search(dir, "IO.inspect(_, _)")
      assert length(results) == 1
    end

    @tag :tmp_dir
    test "returns full source and captures", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "a.ex"), """
      IO.inspect(data, label: "debug")
      """)

      [match] = ExAST.search(dir, "IO.inspect(expr, _)")
      assert match.source =~ "IO.inspect"
      assert Map.has_key?(match.captures, :expr)
    end
  end

  describe "replace/4" do
    @tag :tmp_dir
    test "modifies files and returns count", %{tmp_dir: dir} do
      path = Path.join(dir, "a.ex")

      File.write!(path, """
      IO.inspect(data)
      IO.puts("keep")
      IO.inspect(other)
      """)

      [{^path, 2}] = ExAST.replace(dir, "IO.inspect(expr)", "dbg(expr)")
      content = File.read!(path)
      assert content =~ "dbg(data)"
      assert content =~ "dbg(other)"
      assert content =~ "IO.puts"
    end

    @tag :tmp_dir
    test "dry run does not modify files", %{tmp_dir: dir} do
      path = Path.join(dir, "a.ex")
      File.write!(path, "IO.inspect(data)\n")

      [{^path, 1}] = ExAST.replace(dir, "IO.inspect(expr)", "dbg(expr)", dry_run: true)
      assert File.read!(path) =~ "IO.inspect"
    end

    @tag :tmp_dir
    test "returns empty list when no matches", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "a.ex"), "IO.puts(:ok)\n")
      assert [] = ExAST.replace(dir, "IO.inspect(_)", "dbg(_)")
    end
  end
end
