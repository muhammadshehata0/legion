defmodule Legion.Test.TelemetryLogger do
  @moduledoc """
  Attaches to Legion telemetry events and logs them for test observability.
  """

  require Logger

  @events [
    [:legion, :call, :start],
    [:legion, :call, :stop],
    [:legion, :call, :exception],
    [:legion, :iteration, :start],
    [:legion, :iteration, :stop],
    [:legion, :llm, :request, :start],
    [:legion, :llm, :request, :stop],
    [:legion, :sandbox, :eval, :start],
    [:legion, :sandbox, :eval, :stop],
    [:legion, :human, :input_required],
    [:legion, :human, :input_received]
  ]

  def attach do
    :telemetry.attach_many(
      "legion-test-logger",
      @events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def detach do
    :telemetry.detach("legion-test-logger")
  end

  def handle_event([:legion, :call, :start], _measurements, metadata, _config) do
    safe_puts("\n#{cyan()}━━━ Agent Call Started ━━━#{reset()}")
    safe_puts("  Agent: #{inspect(metadata.agent)}")
    safe_puts("  Task:")
    safe_puts(indent(metadata.task, "    "))
  end

  def handle_event([:legion, :call, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    safe_puts("\n#{green()}━━━ Agent Call Completed ━━━#{reset()}")
    safe_puts("  Duration: #{duration_ms}ms")
    safe_puts("  Agent: #{inspect(metadata.agent)}")
  end

  def handle_event([:legion, :call, :exception], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    safe_puts("\n#{red()}━━━ Agent Call Failed ━━━#{reset()}")
    safe_puts("  Duration: #{duration_ms}ms")
    safe_puts("  Error: #{inspect(metadata.reason)}")
  end

  def handle_event([:legion, :iteration, :start], _measurements, metadata, _config) do
    safe_puts(
      "\n  #{yellow()}▶ [#{inspect(metadata.agent)}] Iteration #{metadata.iteration}#{reset()}"
    )
  end

  def handle_event([:legion, :iteration, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

    safe_puts(
      "  #{yellow()}◀ [#{inspect(metadata.agent)}] Iteration #{metadata.iteration} completed (#{duration_ms}ms)#{reset()}"
    )
  end

  def handle_event([:legion, :llm, :request, :start], _measurements, metadata, _config) do
    request = metadata.request
    safe_puts("    #{blue()}↗ LLM Request#{reset()} (model: #{request.model})")

    safe_puts(
      "      #{dim()}Iteration: #{request.iteration}, Retry: #{request.retry}, Messages: #{request.message_count}#{reset()}"
    )

    # Show messages
    safe_puts("      #{dim()}Messages:#{reset()}")

    Enum.each(request.messages, fn msg ->
      role = msg[:role] || msg["role"]
      content = msg[:content] || msg["content"]
      safe_puts("        #{dim()}[#{role}]#{reset()}")
      safe_puts(indent(content, "          "))
    end)
  end

  def handle_event([:legion, :llm, :request, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    safe_puts("    #{blue()}↙ LLM Response#{reset()} (#{duration_ms}ms)")

    # Show only the object (actual LLM message) from the response
    case Map.get(metadata, :response) do
      nil ->
        :ok

      %{object: object} ->
        safe_puts("      #{dim()}Message:#{reset()}")
        formatted_object = Jason.encode!(object, pretty: true)
        safe_puts(indent(formatted_object, "        "))

      response ->
        # Fallback for responses without object field
        safe_puts("      #{dim()}Response:#{reset()}")
        formatted_response = Jason.encode!(response, pretty: true)
        safe_puts(indent(formatted_response, "        "))
    end
  end

  def handle_event([:legion, :sandbox, :eval, :start], _measurements, metadata, _config) do
    safe_puts("    #{magenta()}⚡ Sandbox Eval#{reset()}")
    safe_puts("    #{dim()}Code:#{reset()}")
    safe_puts(indent(metadata.code, "      "))
  end

  def handle_event([:legion, :sandbox, :eval, :stop], measurements, _metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    safe_puts("    #{magenta()}✓ Sandbox Done#{reset()} (#{duration_ms}ms)")
  end

  def handle_event([:legion, :human, :input_required], _measurements, metadata, _config) do
    safe_puts("    #{cyan()}? Human Input Required#{reset()}")
    safe_puts("      Question: #{metadata.question}")
  end

  def handle_event([:legion, :human, :input_received], _measurements, _metadata, _config) do
    safe_puts("    #{cyan()}✓ Human Input Received#{reset()}")
  end

  # Helpers
  defp safe_puts(text) do
    # Use :user to bypass ExUnit capture and ensure logs are visible immediately
    IO.puts(:user, text)
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  defp indent(text, prefix) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> "#{prefix}#{line}" end)
  end

  # ANSI color helpers
  defp cyan, do: "\e[36m"
  defp green, do: "\e[32m"
  defp red, do: "\e[31m"
  defp yellow, do: "\e[33m"
  defp blue, do: "\e[34m"
  defp magenta, do: "\e[35m"
  defp dim, do: "\e[2m"
  defp reset, do: "\e[0m"
end
