defmodule ExAST.Index.Plan do
  @moduledoc """
  Indexable summary of an ExAST pattern or selector.

  The plan is advisory: callers may use the terms to retrieve candidates, but
  must still verify matches with ExAST to preserve exact semantics.
  """

  @type t :: %__MODULE__{
          required_terms: MapSet.t(String.t()),
          optional_terms: MapSet.t(String.t()),
          negative_terms: MapSet.t(String.t()),
          candidate_groups: [MapSet.t(String.t())],
          requires_source?: boolean(),
          requires_comments?: boolean()
        }

  defstruct required_terms: MapSet.new(),
            optional_terms: MapSet.new(),
            negative_terms: MapSet.new(),
            candidate_groups: [],
            requires_source?: false,
            requires_comments?: false
end
