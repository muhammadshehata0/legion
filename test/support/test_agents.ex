# Test agent and tool module definitions shared across integration and unit tests

defmodule Legion.Test.MathTool do
  @moduledoc """
  A math tool for performing arithmetic operations.
  """
  use Legion.Tool

  @doc "Adds two numbers together"
  def add(a, b), do: a + b

  @doc "Subtracts the second number from the first"
  def subtract(a, b), do: a - b

  @doc "Multiplies two numbers"
  def multiply(a, b), do: a * b

  @doc "Divides the first number by the second"
  def divide(a, b) when b != 0, do: a / b
  def divide(_, 0), do: {:error, :division_by_zero}
end

defmodule Legion.Test.AdvancedMathTool do
  @moduledoc """
  Advanced mathematical operations.
  """
  use Legion.Tool

  @doc "Calculates the power of a number (base^exponent)"
  def power(base, exponent), do: :math.pow(base, exponent)

  @doc "Calculates the square root of a number"
  def sqrt(n) when n >= 0, do: :math.sqrt(n)

  @doc "Calculates the factorial of a non-negative integer"
  def factorial(0), do: 1
  def factorial(n) when n > 0, do: n * factorial(n - 1)
end

defmodule Legion.Test.StatsTool do
  @moduledoc """
  Statistical operations on lists of numbers.
  """
  use Legion.Tool

  @doc "Calculates the mean (average) of a list of numbers"
  def mean([_ | _] = numbers) do
    Enum.sum(numbers) / length(numbers)
  end

  @doc "Calculates the sum of a list of numbers"
  def sum(numbers) when is_list(numbers), do: Enum.sum(numbers)

  @doc "Finds the minimum value in a list of numbers"
  def min([_ | _] = numbers) do
    Enum.min(numbers)
  end

  @doc "Finds the maximum value in a list of numbers"
  def max([_ | _] = numbers) do
    Enum.max(numbers)
  end
end

defmodule Legion.Test.MathAgent do
  @moduledoc """
  An AI agent that performs mathematical calculations.
  Use the available math tools to solve problems.
  """
  use Legion.AIAgent, tools: [Legion.Test.MathTool, Legion.Test.AdvancedMathTool]

  @impl true
  def output_schema do
    [
      result: [type: :float, required: true],
      explanation: [type: :string, required: true]
    ]
  end
end

defmodule Legion.Test.ComprehensiveMathAgent do
  @moduledoc """
  A comprehensive math agent with arithmetic, advanced math, and statistics capabilities.
  Use the appropriate tool for each calculation:
  - MathTool: Basic arithmetic (add, subtract, multiply, divide)
  - AdvancedMathTool: Power, square root, factorial
  - StatsTool: Mean, sum, min, max on lists
  """
  use Legion.AIAgent,
    tools: [Legion.Test.MathTool, Legion.Test.AdvancedMathTool, Legion.Test.StatsTool]

  @impl true
  def output_schema do
    [
      result: [type: :float, required: true],
      steps: [type: {:list, :string}, required: true],
      explanation: [type: :string, required: true]
    ]
  end

  @impl true
  def config do
    %{
      max_iterations: 15,
      max_retries: 3
    }
  end
end
