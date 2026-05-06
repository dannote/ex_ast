defmodule ExAST.Symbol.Reference do
  @moduledoc "A local or remote reference found in Elixir code."

  @type kind :: :local_call | :remote_call | :alias | :module_attribute

  @type t :: %__MODULE__{
          kind: kind(),
          module: String.t() | nil,
          name: String.t(),
          arity: non_neg_integer() | nil,
          qualified_name: String.t(),
          mfa: {module(), atom(), non_neg_integer()} | nil,
          line: pos_integer() | nil,
          column: pos_integer() | nil,
          node: Macro.t()
        }

  defstruct [:kind, :module, :name, :arity, :qualified_name, :mfa, :line, :column, :node]
end
