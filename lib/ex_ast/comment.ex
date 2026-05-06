defmodule ExAST.Comment do
  @moduledoc "A source comment with line/column metadata."

  @type t :: %__MODULE__{
          text: String.t(),
          line: pos_integer() | nil,
          column: pos_integer() | nil,
          previous_eol_count: non_neg_integer() | nil,
          next_eol_count: non_neg_integer() | nil
        }

  defstruct [:text, :line, :column, :previous_eol_count, :next_eol_count]
end
