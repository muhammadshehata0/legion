defmodule Legion.SandboxTest do
  use ExUnit.Case, async: true

  alias Legion.Sandbox

  describe "eval/3" do
    test "evaluates simple expressions" do
      assert {:ok, 3} = Sandbox.eval("1 + 2", Dune.Allowlist.Default)
    end

    test "evaluates complex expressions" do
      code = """
      [1, 2, 3, 4, 5]
      |> Enum.map(&(&1 * 2))
      |> Enum.sum()
      """

      assert {:ok, 30} = Sandbox.eval(code, Dune.Allowlist.Default)
    end

    test "returns error for runtime exceptions" do
      assert {:error, %{type: :exception}} = Sandbox.eval("1 / 0", Dune.Allowlist.Default)
    end

    test "allows standard library functions" do
      assert {:ok, "hello world"} =
               Sandbox.eval(~s|String.downcase("HELLO WORLD")|, Dune.Allowlist.Default)
    end

    test "allows Enum functions" do
      assert {:ok, [2, 4, 6]} =
               Sandbox.eval("Enum.map([1, 2, 3], &(&1 * 2))", Dune.Allowlist.Default)
    end

    test "restricts dangerous functions" do
      assert {:error, %{type: :restricted}} =
               Sandbox.eval("File.cwd!()", Dune.Allowlist.Default)
    end
  end

  describe "eval/3 with custom allowlist" do
    defmodule TestMathTool do
      use Legion.Tool

      def add(a, b), do: a + b
      def multiply(a, b), do: a * b
    end

    defmodule TestAllowlist do
      use Dune.Allowlist, extend: Dune.Allowlist.Default
      allow(Legion.SandboxTest.TestMathTool, :all)
    end

    test "allows tool module calls with custom allowlist" do
      assert {:ok, 7} =
               Sandbox.eval(
                 "Legion.SandboxTest.TestMathTool.add(3, 4)",
                 TestAllowlist
               )
    end

    test "restricts tool module calls without proper allowlist" do
      assert {:error, %{type: :restricted}} =
               Sandbox.eval(
                 "Legion.SandboxTest.TestMathTool.add(3, 4)",
                 Dune.Allowlist.Default
               )
    end
  end
end
