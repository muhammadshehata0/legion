defmodule Legion.Observability.Telemetry do
  # TODO: Here we need to think how to log actual requests (see how Req is doing this)
  @moduledoc """
  Telemetry events for Legion agents.

  Legion emits the following telemetry events:

  ## Agent Call Events

  - `[:legion, :call, :start]` - Emitted when an agent call begins
    - Measurements: `%{system_time: integer}`
    - Metadata: `%{agent: module, task: String.t}`

  - `[:legion, :call, :stop]` - Emitted when an agent call completes successfully
    - Measurements: `%{duration: integer}`
    - Metadata: `%{agent: module, task: String.t, iterations: integer}`

  - `[:legion, :call, :exception]` - Emitted when an agent call fails
    - Measurements: `%{duration: integer}`
    - Metadata: `%{agent: module, task: String.t, kind: atom, reason: term, stacktrace: list}`

  ## Iteration Events

  - `[:legion, :iteration, :start]` - Emitted at the start of each iteration
    - Measurements: `%{system_time: integer}`
    - Metadata: `%{agent: module, iteration: integer}`

  - `[:legion, :iteration, :stop]` - Emitted at the end of each iteration
    - Measurements: `%{duration: integer}`
    - Metadata: `%{agent: module, iteration: integer, action: atom}`

  ## LLM Request Events

  - `[:legion, :llm, :request, :start]` - Emitted before calling the LLM
    - Measurements: `%{system_time: integer}`
    - Metadata: `%{agent: module, model: String.t, request: Legion.Observability.LLMRequest.t}`
      - The `request` field contains a struct with detailed request information:
        - `model`: The LLM model identifier
        - `messages`: The full conversation history being sent
        - `message_count`: Number of messages in the request
        - `iteration`: Current iteration number
        - `retry`: Current retry attempt number

  - `[:legion, :llm, :request, :stop]` - Emitted after LLM response
    - Measurements: `%{duration: integer}`
    - Metadata: `%{agent: module, model: String.t, request: Legion.Observability.LLMRequest.t, response: map | nil}`
      - The `response` field contains the structured LLM response (when successful)

  ## Sandbox Events

  - `[:legion, :sandbox, :eval, :start]` - Emitted before code evaluation
    - Measurements: `%{system_time: integer}`
    - Metadata: `%{agent: module, code: String.t}`

  - `[:legion, :sandbox, :eval, :stop]` - Emitted after code evaluation
    - Measurements: `%{duration: integer}`
    - Metadata: `%{agent: module, success: boolean}`

  ## Human Input Events

  - `[:legion, :human, :input_required]` - Emitted when human input is requested
    - Measurements: `%{system_time: integer}`
    - Metadata: `%{agent: module, question: String.t, type: atom}`

  - `[:legion, :human, :input_received]` - Emitted when human input is received
    - Measurements: `%{duration: integer}`
    - Metadata: `%{agent: module}`
  """

  @doc """
  Executes the given function and emits start/stop/exception telemetry events.

  ## Parameters
    - event_prefix: The event name prefix (e.g., `[:legion, :call]`)
    - metadata: Metadata to include with all events
    - function: The function to execute

  ## Returns
    The result of the function, or re-raises any exception
  """
  @spec span(list(atom()), map(), (-> result)) :: result when result: any()
  def span(event_prefix, metadata, function) when is_function(function, 0) do
    start_time = System.monotonic_time()
    start_metadata = Map.put(metadata, :system_time, System.system_time())

    :telemetry.execute(
      event_prefix ++ [:start],
      %{system_time: System.system_time()},
      start_metadata
    )

    try do
      result = function.()
      duration = System.monotonic_time() - start_time

      :telemetry.execute(
        event_prefix ++ [:stop],
        %{duration: duration},
        metadata
      )

      result
    rescue
      exception ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{
            kind: :error,
            reason: exception,
            stacktrace: __STACKTRACE__
          })
        )

        reraise exception, __STACKTRACE__
    catch
      kind, reason ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{
            kind: kind,
            reason: reason,
            stacktrace: __STACKTRACE__
          })
        )

        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  @doc """
  Executes the given function and emits start/stop/exception telemetry events,
  enriching the stop event metadata based on the function result.

  The function should return `{result, metadata_updates}` where `metadata_updates`
  is a map that will be merged into the stop event metadata.

  ## Parameters
    - event_prefix: The event name prefix (e.g., `[:legion, :llm, :request]`)
    - metadata: Base metadata to include with all events
    - function: The function to execute, should return `{result, metadata_updates}`

  ## Returns
    The result (first element of the tuple), or re-raises any exception

  ## Example

      Telemetry.span_with_metadata(
        [:legion, :llm, :request],
        %{agent: MyAgent, model: "gpt-4"},
        fn ->
          {:ok, response} = call_llm()
          {{:ok, response}, %{response: response}}
        end
      )
  """
  @spec span_with_metadata(list(atom()), map(), (-> {result, map()})) :: result when result: any()
  def span_with_metadata(event_prefix, metadata, function) when is_function(function, 0) do
    start_time = System.monotonic_time()
    start_metadata = Map.put(metadata, :system_time, System.system_time())

    :telemetry.execute(
      event_prefix ++ [:start],
      %{system_time: System.system_time()},
      start_metadata
    )

    try do
      {result, extra_metadata} = function.()
      duration = System.monotonic_time() - start_time

      stop_metadata = Map.merge(metadata, extra_metadata)

      :telemetry.execute(
        event_prefix ++ [:stop],
        %{duration: duration},
        stop_metadata
      )

      result
    rescue
      exception ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{
            kind: :error,
            reason: exception,
            stacktrace: __STACKTRACE__
          })
        )

        reraise exception, __STACKTRACE__
    catch
      kind, reason ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          event_prefix ++ [:exception],
          %{duration: duration},
          Map.merge(metadata, %{
            kind: kind,
            reason: reason,
            stacktrace: __STACKTRACE__
          })
        )

        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  @doc """
  Emits a simple telemetry event.
  """
  @spec emit(list(atom()), map(), map()) :: :ok
  def emit(event, measurements, metadata) do
    :telemetry.execute(event, measurements, metadata)
  end
end
