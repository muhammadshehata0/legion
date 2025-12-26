defmodule Legion.Test.IntegrationHelpers do
  @moduledoc """
  Helper macros for integration tests.

  Automatically wraps tests tagged with @tag :integration in an API key check.
  """

  defmacro __using__(_opts) do
    quote do
      import Legion.Test.IntegrationHelpers
    end
  end

  @doc """
  Wraps a block of code with an API key check.

  If OPENAI_API_KEY is not set, the block is skipped and :ok is returned.
  Otherwise, the block is executed.

  ## Example

      test "some integration test" do
        with_api_key do
          # test code that needs API key
        end
      end
  """
  defmacro with_api_key(do: block) do
    quote do
      case System.get_env("OPENAI_API_KEY") do
        nil ->
          IO.puts("\nSkipping test - OPENAI_API_KEY not set")
          :ok

        _key ->
          unquote(block)
      end
    end
  end

  @doc """
  Custom test macro that automatically wraps integration tests with API key check.

  If the test has @tag :integration, it will automatically check for OPENAI_API_KEY
  and skip if not present.
  """
  defmacro integration_test(message, var \\ quote(do: _), contents) do
    contents =
      case contents do
        [do: block] ->
          quote do
            case System.get_env("OPENAI_API_KEY") do
              nil ->
                IO.puts("\nSkipping integration test - OPENAI_API_KEY not set")
                :ok

              _key ->
                unquote(block)
            end
          end

        _ ->
          quote do: raise("integration_test requires a do: block")
      end

    var = Macro.escape(var)
    contents = Macro.escape(contents, unquote: true)

    quote bind_quoted: [var: var, contents: contents, message: message] do
      @tag :integration
      test(message, var, do: unquote(contents))
    end
  end
end
