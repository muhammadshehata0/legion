defmodule Legion.Sandbox do
  @moduledoc """
  Sandboxed code evaluation using Dune.

  Provides a secure environment for executing LLM-generated Elixir code
  with configurable resource limits and module allowlists.
  """

  @doc """
  Evaluates code in a sandboxed environment.

  ## Parameters
    - code: The Elixir code string to evaluate
    - allowlist: Module implementing `Dune.Allowlist` behaviour
    - opts: Dune options including:
      - `:timeout` - Max execution time in ms (default: 50)
      - `:max_heap_size` - Memory limit (default: 50_000)
      - `:max_reductions` - CPU cycles limit (default: 30_000)

  ## Returns
    - `{:ok, result}` - Code executed successfully
    - `{:error, reason}` - Execution failed (with error message)

  ## Example

      iex> Legion.Sandbox.eval("1 + 2", Dune.Allowlist.Default)
      {:ok, 3}

      iex> Legion.Sandbox.eval("File.cwd!()", Dune.Allowlist.Default)
      {:error, %{type: :restricted, message: "** (DuneRestrictedError) function File.cwd!/0 is restricted"}}
  """
  @spec eval(String.t(), module(), keyword()) :: {:ok, any()} | {:error, map()}
  def eval(code, allowlist, opts \\ []) do
    dune_opts = Keyword.put(opts, :allowlist, allowlist)

    case Dune.eval_string(code, dune_opts) do
      %Dune.Success{value: value, stdio: stdio} ->
        # TODO: Redirect this to stdio as it was before
        if stdio != "", do: IO.puts("Sandbox stdio output:\n#{stdio}")
        {:ok, value}

      %Dune.Failure{type: type, message: message, stdio: stdio} ->
        if stdio != "", do: IO.puts("Sandbox stdio output:\n#{stdio}")
        {:error, %{type: type, message: message}}
    end
  end
end
