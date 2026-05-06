defmodule ExAST.Symbol.Definition do
  @moduledoc "A module, function, macro, callback, or attribute definition found in Elixir code."

  @type kind ::
          :module
          | :def
          | :defp
          | :defmacro
          | :defmacrop
          | :defdelegate
          | :defcallback
          | :defmacrocallback
          | :attribute
  @type visibility :: :public | :private | nil

  @type t :: %__MODULE__{
          kind: kind(),
          module: String.t() | nil,
          name: String.t(),
          arity: non_neg_integer() | nil,
          qualified_name: String.t(),
          mfa: {module(), atom(), non_neg_integer()} | nil,
          visibility: visibility(),
          line: pos_integer() | nil,
          column: pos_integer() | nil,
          node: Macro.t()
        }

  defstruct [
    :kind,
    :module,
    :name,
    :arity,
    :qualified_name,
    :mfa,
    :visibility,
    :line,
    :column,
    :node
  ]
end
