defmodule ExAST.Symbols do
  @moduledoc """
  Extracts lightweight definition and reference facts from Elixir source or AST.
  """

  alias ExAST.Symbol.{Definition, Reference}

  @definition_forms [:def, :defp, :defmacro, :defmacrop]
  @callback_forms [:defcallback, :defmacrocallback]

  @spec definitions(String.t() | Macro.t()) :: [Definition.t()]
  def definitions(source_or_ast) do
    source_or_ast
    |> to_ast()
    |> collect_definitions([])
  end

  @spec references(String.t() | Macro.t()) :: [Reference.t()]
  def references(source_or_ast) do
    {_ast, references} =
      source_or_ast
      |> to_ast()
      |> Macro.prewalk([], fn node, acc ->
        references = references_from_node(node)
        {node, references ++ acc}
      end)

    Enum.reverse(references)
  end

  defp collect_definitions(list, modules) when is_list(list) do
    Enum.flat_map(list, &collect_definitions(&1, modules))
  end

  defp collect_definitions({:__block__, _meta, expressions}, modules) do
    collect_definitions(expressions, modules)
  end

  defp collect_definitions({:defmodule, _meta, [_module_ast, [do: body]]} = node, modules) do
    case definition_from_node(node, modules) do
      {:module, definition, module_name} ->
        [definition | collect_definitions(body, [module_name | modules])]

      :none ->
        collect_definitions(body, modules)
    end
  end

  defp collect_definitions({:defmodule, _meta, [_module_ast, body]} = node, modules) do
    case definition_from_node(node, modules) do
      {:module, definition, module_name} ->
        [definition | collect_definitions(body, [module_name | modules])]

      :none ->
        collect_definitions(body, modules)
    end
  end

  defp collect_definitions(node, modules) when is_tuple(node) do
    own =
      case definition_from_node(node, modules) do
        {:definition, definition} -> [definition]
        _other -> []
      end

    children = node |> Tuple.to_list() |> collect_definitions(modules)
    own ++ children
  end

  defp collect_definitions(_node, _modules), do: []

  defp definition_from_node({:defmodule, meta, [module_ast, _body]} = node, _modules) do
    case alias_name(module_ast) do
      {:ok, name} ->
        definition = %Definition{
          kind: :module,
          module: name,
          name: name,
          arity: nil,
          qualified_name: name,
          visibility: :public,
          line: meta[:line],
          column: meta[:column],
          node: node
        }

        {:module, definition, name}

      :error ->
        :none
    end
  end

  defp definition_from_node({form, meta, [head | _rest]} = node, modules)
       when form in @definition_forms do
    case function_head(head) do
      {:ok, name, arity} ->
        module = List.first(modules)

        {:definition,
         %Definition{
           kind: form,
           module: module,
           name: Atom.to_string(name),
           arity: arity,
           qualified_name: qualified_name(module, name, arity),
           visibility: visibility(form),
           line: meta[:line],
           column: meta[:column],
           node: node
         }}

      :unknown ->
        :none
    end
  end

  defp definition_from_node({form, meta, [head | _rest]} = node, modules)
       when form in @callback_forms do
    callback_definition(node, meta, modules, form, head)
  end

  defp definition_from_node({:defdelegate, meta, [head | _rest]} = node, modules) do
    case function_head(head) do
      {:ok, name, arity} ->
        module = List.first(modules)

        {:definition,
         %Definition{
           kind: :defdelegate,
           module: module,
           name: Atom.to_string(name),
           arity: arity,
           qualified_name: qualified_name(module, name, arity),
           visibility: :public,
           line: meta[:line],
           column: meta[:column],
           node: node
         }}

      :unknown ->
        :none
    end
  end

  defp definition_from_node({:@, meta, [{:callback, _, [head]}]} = node, modules) do
    callback_definition(node, meta, modules, :defcallback, head)
  end

  defp definition_from_node({:@, meta, [{:macrocallback, _, [head]}]} = node, modules) do
    callback_definition(node, meta, modules, :defmacrocallback, head)
  end

  defp definition_from_node({:@, meta, [{name, _, _args}]} = node, modules) when is_atom(name) do
    module = List.first(modules)

    {:definition,
     %Definition{
       kind: :attribute,
       module: module,
       name: Atom.to_string(name),
       arity: nil,
       qualified_name: attribute_name(module, name),
       visibility: nil,
       line: meta[:line],
       column: meta[:column],
       node: node
     }}
  end

  defp definition_from_node(_node, _modules), do: :none

  defp callback_definition(node, meta, modules, kind, head) do
    case callback_head(head) do
      {:ok, name, arity} ->
        module = List.first(modules)

        {:definition,
         %Definition{
           kind: kind,
           module: module,
           name: Atom.to_string(name),
           arity: arity,
           qualified_name: qualified_name(module, name, arity),
           visibility: :public,
           line: meta[:line],
           column: meta[:column],
           node: node
         }}

      :unknown ->
        :none
    end
  end

  defp references_from_node({{:., meta, [module_ast, name]}, _call_meta, args} = node)
       when is_atom(name) and is_list(args) do
    case alias_name(module_ast) do
      {:ok, module} ->
        [
          %Reference{
            kind: :remote_call,
            module: module,
            name: Atom.to_string(name),
            arity: length(args),
            qualified_name: "#{module}.#{name}/#{length(args)}",
            line: meta[:line],
            column: meta[:column],
            node: node
          }
        ]

      :error ->
        []
    end
  end

  defp references_from_node({:@, meta, [{name, _, _args}]} = node) when is_atom(name) do
    [
      %Reference{
        kind: :module_attribute,
        module: nil,
        name: Atom.to_string(name),
        arity: nil,
        qualified_name: "@#{name}",
        line: meta[:line],
        column: meta[:column],
        node: node
      }
    ]
  end

  defp references_from_node({:__aliases__, meta, parts} = node) when is_list(parts) do
    if Enum.all?(parts, &is_atom/1) do
      name = Enum.join(parts, ".")

      [
        %Reference{
          kind: :alias,
          module: name,
          name: name,
          arity: nil,
          qualified_name: name,
          line: meta[:line],
          column: meta[:column],
          node: node
        }
      ]
    else
      []
    end
  end

  defp references_from_node({name, meta, args} = node)
       when is_atom(name) and is_list(args) and
              name not in [
                :__aliases__,
                :...,
                :_,
                :.,
                :@,
                :defmodule,
                :defdelegate,
                :def,
                :defp,
                :defmacro,
                :defmacrop,
                :defcallback,
                :defmacrocallback
              ] do
    [
      %Reference{
        kind: :local_call,
        module: nil,
        name: Atom.to_string(name),
        arity: length(args),
        qualified_name: "#{name}/#{length(args)}",
        line: meta[:line],
        column: meta[:column],
        node: node
      }
    ]
  end

  defp references_from_node(_node), do: []

  defp function_head({:when, _, [head | _guards]}), do: function_head(head)
  defp function_head({name, _, nil}) when is_atom(name), do: {:ok, name, 0}

  defp function_head({name, _, args}) when is_atom(name) and is_list(args),
    do: {:ok, name, length(args)}

  defp function_head(_head), do: :unknown

  defp callback_head({:"::", _, [{name, _, args}, _type]}) when is_atom(name) and is_list(args),
    do: {:ok, name, length(args)}

  defp callback_head({name, _, args}) when is_atom(name) and is_list(args),
    do: {:ok, name, length(args)}

  defp callback_head(_head), do: :unknown

  defp alias_name({:__aliases__, _, parts}) when is_list(parts) do
    if Enum.all?(parts, &is_atom/1), do: {:ok, Enum.join(parts, ".")}, else: :error
  end

  defp alias_name(atom) when is_atom(atom), do: {:ok, Atom.to_string(atom)}
  defp alias_name(_ast), do: :error

  defp qualified_name(nil, name, arity), do: "#{name}/#{arity}"
  defp qualified_name(module, name, arity), do: "#{module}.#{name}/#{arity}"

  defp attribute_name(nil, name), do: "@#{name}"
  defp attribute_name(module, name), do: "#{module}.@#{name}"

  defp visibility(:defp), do: :private
  defp visibility(:defmacrop), do: :private
  defp visibility(_form), do: :public

  defp to_ast(source) when is_binary(source), do: Sourceror.parse_string!(source)
  defp to_ast(ast), do: ast
end
