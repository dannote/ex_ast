defmodule ExAST.SymbolsTest do
  use ExUnit.Case, async: true

  alias ExAST.Symbols

  test "extracts module, function, macro, delegate, callback, and attribute definitions" do
    definitions =
      Symbols.definitions("""
      defmodule Example do
        @behaviour GenServer
        @callback handle(term()) :: term()
        def run(arg), do: Repo.transaction(fn -> arg end)
        defp helper, do: :ok
        defmacro build(expr), do: expr
        defdelegate delegated(arg), to: Other
      end

      defmodule OtherModule do
        def other, do: :ok
      end
      """)

    qualified_names = Enum.map(definitions, & &1.qualified_name)

    assert "Example" in qualified_names
    assert "Example.@behaviour" in qualified_names
    assert "Example.handle/1" in qualified_names
    assert "Example.run/1" in qualified_names
    assert "Example.helper/0" in qualified_names
    assert "Example.build/1" in qualified_names
    assert "Example.delegated/1" in qualified_names
    assert "OtherModule.other/0" in qualified_names
    refute "Example.other/0" in qualified_names

    assert Enum.find(definitions, &(&1.qualified_name == "Example.run/1")).mfa ==
             {Example, :run, 1}
  end

  test "extracts remote and local references" do
    references =
      Symbols.references("""
      defmodule Example do
        def run(arg) do
          Repo.transaction(fn -> helper(arg) end)
        end
      end
      """)

    qualified_names = Enum.map(references, & &1.qualified_name)

    assert "Repo.transaction/1" in qualified_names
    assert "helper/1" in qualified_names
    refute "def/2" in qualified_names
    refute "defmodule/2" in qualified_names
  end

  test "normalizes and matches qualified names and MFA tuples" do
    reference =
      Symbols.references("""
      Enum.map(items, & &1.id)
      """)
      |> Enum.find(&(&1.qualified_name == "Enum.map/2"))

    assert reference.mfa == {Enum, :map, 2}
    assert Symbols.qualified_name({Enum, :map, 2}) == "Enum.map/2"
    assert Symbols.qualified_name({"Enum", :map, 2}) == "Enum.map/2"
    assert Symbols.mfa("Enum.map/2") == {Enum, :map, 2}
    assert Symbols.matches?(reference, {Enum, :map, 2})
    assert Symbols.matches?(reference, "Enum.map/2")
  end
end
