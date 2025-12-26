defmodule Legion.Observability.LLMRequest do
  @moduledoc """
  Represents an LLM request with all relevant metadata for observability.

  This struct is used in telemetry events to provide detailed information
  about LLM requests, including the actual messages being sent, configuration,
  and context information.
  """

  @type message :: %{role: String.t(), content: String.t()}

  @type t :: %__MODULE__{
          model: String.t(),
          messages: list(message()),
          message_count: non_neg_integer(),
          iteration: non_neg_integer(),
          retry: non_neg_integer()
        }

  @enforce_keys [:model, :messages, :message_count, :iteration, :retry]
  defstruct [:model, :messages, :message_count, :iteration, :retry]

  @doc """
  Creates a new LLM request struct from the given parameters.

  ## Parameters
    - model: The LLM model identifier
    - messages: The conversation messages being sent to the LLM
    - iteration: The current iteration number
    - retry: The current retry attempt number

  ## Returns
    A new `Legion.Observability.LLMRequest` struct
  """
  @spec new(String.t(), list(message()), non_neg_integer(), non_neg_integer()) :: t()
  def new(model, messages, iteration, retry) do
    %__MODULE__{
      model: model,
      messages: messages,
      message_count: length(messages),
      iteration: iteration,
      retry: retry
    }
  end
end
