defmodule Droodotfoo.Plugins.Calculator do
  @moduledoc """
  Calculator plugin with basic arithmetic and RPN support.

  Supports two modes:
  - **Standard mode**: Traditional infix notation (e.g., "2 + 2")
  - **RPN mode**: Reverse Polish Notation with stack-based operations

  ## Features

  - Basic arithmetic operations: +, -, *, /, ^
  - Expression evaluation with order of operations
  - Stack-based RPN calculations
  - Calculation history tracking
  - Memory storage (planned)

  ## Usage

  Standard mode: Enter expressions like `5 + 3`, `10 * 2`, `100 / 4`
  RPN mode: Enter numbers and operators separately (`5`, `3`, `+`)

  ## Commands

  - `rpn` - Switch to RPN mode
  - `std` - Switch to standard mode
  - `clear` - Clear display and stack
  - `help` - Show detailed help
  - `q` - Quit calculator
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

  alias Droodotfoo.Plugins.GameBase

  import Droodotfoo.Plugins.UIHelpers

  @type mode :: :standard | :rpn
  @type state :: %__MODULE__{
          mode: mode(),
          display: String.t(),
          stack: [number()],
          history: [String.t()],
          memory: number()
        }
  @type terminal_state :: map()
  @type render_output :: [String.t()]
  @type input_result ::
          {:continue, state(), render_output()}
          | {:exit, render_output()}
          | {:error, String.t()}

  defstruct [
    :mode,
    :display,
    :stack,
    :history,
    :memory
  ]

  # Plugin Behaviour Callbacks

  @impl true
  @spec metadata() :: map()
  def metadata do
    GameBase.game_metadata(
      "calc",
      "1.0.0",
      "Calculator with standard and RPN modes",
      "droo.foo",
      ["calc", "calculator"],
      :tool
    )
  end

  @impl true
  @spec init(terminal_state()) :: {:ok, state()}
  def init(_terminal_state) do
    initial_state = %__MODULE__{
      mode: :standard,
      display: "0",
      stack: [],
      history: [],
      memory: 0
    }

    {:ok, initial_state}
  end

  @impl true
  @spec handle_input(String.t(), state(), terminal_state()) :: input_result()
  def handle_input(input, state, _terminal_state) do
    input = String.trim(input)

    cond do
      input in ["q", "Q", "quit", "exit"] ->
        {:exit, ["Calculator closed. Last result: #{state.display}"]}

      input == "rpn" ->
        new_state = %{state | mode: :rpn, stack: []}
        {:continue, new_state, render(new_state, %{})}

      input == "std" ->
        new_state = %{state | mode: :standard}
        {:continue, new_state, render(new_state, %{})}

      input == "clear" or input == "c" ->
        new_state = %{state | display: "0", stack: []}
        {:continue, new_state, render(new_state, %{})}

      input == "help" ->
        {:continue, state, render_help()}

      state.mode == :rpn ->
        handle_rpn_input(input, state)

      true ->
        handle_standard_input(input, state)
    end
  end

  @impl true
  @spec render(state(), terminal_state()) :: render_output()
  def render(state, _terminal_state) do
    title = "CALCULATOR - Mode: #{state.mode |> to_string() |> String.upcase()}"
    header = header_left(title, 50)

    display_section = [
      "",
      "Display: #{state.display}",
      ""
    ]

    stack_section =
      if state.mode == :rpn and state.stack != [] do
        ["Stack:"] ++
          Enum.map(Enum.reverse(state.stack), fn val ->
            "  #{val}"
          end) ++ [""]
      else
        []
      end

    history_section =
      if state.history != [] do
        recent = Enum.take(state.history, -5)

        ["Recent:"] ++
          Enum.map(recent, fn entry ->
            "  #{entry}"
          end) ++ [""]
      else
        []
      end

    instructions = [
      "-" |> String.duplicate(50),
      "Commands:",
      "  Standard mode: Enter expressions (e.g., '2 + 2')",
      "  RPN mode: Enter numbers and operators separately",
      "  'rpn' - Switch to RPN mode",
      "  'std' - Switch to standard mode",
      "  'clear' - Clear display",
      "  'help' - Show detailed help",
      "  'q' - Quit calculator",
      "-" |> String.duplicate(50)
    ]

    header ++ display_section ++ stack_section ++ history_section ++ instructions
  end

  @impl true
  @spec cleanup(state()) :: :ok
  def cleanup(_state) do
    :ok
  end

  # Private Functions

  defp handle_standard_input(input, state) do
    case evaluate_expression(input) do
      {:ok, result} ->
        new_state = %{
          state
          | display: format_number(result),
            history: state.history ++ ["#{input} = #{format_number(result)}"]
        }

        {:continue, new_state, render(new_state, %{})}

      {:error, _reason} ->
        {:continue, state, ["Error: Invalid expression"] ++ render(state, %{})}
    end
  end

  defp handle_rpn_input(input, state) do
    cond do
      # Check if it's a number
      number?(input) ->
        {num, _} = Float.parse(input)
        new_state = %{state | stack: [num | state.stack]}
        {:continue, new_state, render(new_state, %{})}

      # Check if it's an operator
      input in ["+", "-", "*", "/", "^"] ->
        case apply_rpn_operator(input, state.stack) do
          {:ok, new_stack, result} ->
            new_state = %{
              state
              | stack: new_stack,
                display: format_number(result),
                history: state.history ++ ["RPN: #{input} = #{format_number(result)}"]
            }

            {:continue, new_state, render(new_state, %{})}

          {:error, reason} ->
            {:continue, state, ["Error: #{reason}"] ++ render(state, %{})}
        end

      true ->
        {:continue, state, ["Error: Invalid input"] ++ render(state, %{})}
    end
  end

  defp evaluate_expression(expr) do
    expr
    |> String.replace(" ", "")
    |> do_evaluate()
  end

  defp do_evaluate(expr) do
    result = parse_and_compute(expr)
    {:ok, result}
  catch
    :division_by_zero -> {:error, "Division by zero"}
    :invalid_expression -> {:error, "Invalid expression"}
    _ -> {:error, "Calculation error"}
  end

  defp parse_and_compute(expr) do
    case Regex.run(~r/^(-?\d+(?:\.\d+)?)([\+\-\*\/\^])(-?\d+(?:\.\d+)?)$/, expr) do
      [_, left, op, right] ->
        evaluate_binary_operation(left, op, right)

      _ ->
        parse_single_value_or_complex(expr)
    end
  end

  defp evaluate_binary_operation(left, op, right) do
    {l, _} = Float.parse(left)
    {r, _} = Float.parse(right)
    apply_operator(op, l, r)
  end

  defp apply_operator("+", l, r), do: l + r
  defp apply_operator("-", l, r), do: l - r
  defp apply_operator("*", l, r), do: l * r
  defp apply_operator("/", _l, r) when r == 0.0, do: throw(:division_by_zero)
  defp apply_operator("/", l, r), do: l / r
  defp apply_operator("^", l, r), do: :math.pow(l, r)

  defp parse_single_value_or_complex(expr) do
    case Float.parse(expr) do
      {num, ""} -> num
      _ -> evaluate_with_precedence(expr)
    end
  end

  defp evaluate_with_precedence(expr) do
    # Tokenize the expression
    tokens = tokenize_expression(expr)

    # Apply order of operations
    tokens
    |> apply_expression_operations(["*", "/"])
    |> apply_expression_operations(["+", "-"])
    |> List.first()
    |> case do
      nil -> throw(:invalid_expression)
      num -> num
    end
  end

  defp tokenize_expression(expr) do
    # Parse expression into tokens (numbers and operators)
    Regex.scan(~r/(-?\d+(?:\.\d+)?|[\+\-\*\/])/, expr)
    |> Enum.map(&List.first/1)
    |> Enum.map(fn token ->
      case Float.parse(token) do
        {num, ""} -> num
        _ -> token
      end
    end)
  end

  defp apply_expression_operations(tokens, ops) do
    case tokens do
      [left, op, right | rest] when is_binary(op) ->
        if op in ops do
          result = calculate_operation(left, op, right)
          apply_expression_operations([result | rest], ops)
        else
          [left | apply_expression_operations([op, right | rest], ops)]
        end

      [token | rest] ->
        [token | apply_expression_operations(rest, ops)]

      [] ->
        []
    end
  end

  defp calculate_operation(left, op, right) when is_number(left) and is_number(right) do
    case op do
      "+" -> left + right
      "-" -> left - right
      "*" -> left * right
      "/" when right != 0 -> left / right
      "/" -> throw(:division_by_zero)
      _ -> throw(:invalid_expression)
    end
  end

  defp calculate_operation(_, _, _), do: throw(:invalid_expression)

  defp apply_rpn_operator(_op, stack) when length(stack) < 2 do
    {:error, "Not enough values on stack"}
  end

  defp apply_rpn_operator(op, [b, a | rest]) do
    result =
      case op do
        "+" -> a + b
        "-" -> a - b
        "*" -> a * b
        "/" when b != 0 -> a / b
        "/" -> {:error, "Division by zero"}
        "^" -> :math.pow(a, b)
      end

    case result do
      {:error, _} = error -> error
      num -> {:ok, [num | rest], num}
    end
  end

  defp number?(str) do
    case Float.parse(str) do
      {_, ""} -> true
      _ -> false
    end
  end

  defp format_number(num) when is_float(num) do
    if num == Float.round(num) do
      num |> round() |> Integer.to_string()
    else
      Float.to_string(num)
    end
  end

  defp format_number(num), do: to_string(num)

  defp render_help do
    header_left("CALCULATOR HELP", 50) ++
      [
        "",
        "STANDARD MODE:",
        "  Enter expressions like: 2 + 2, 10 * 5, 100 / 4",
        "  Operators: + - * / ^",
        "",
        "RPN MODE (Reverse Polish Notation):",
        "  Enter numbers to push onto stack",
        "  Enter operators to perform operations",
        "  Example: '5' '3' '+' results in 8",
        "",
        "COMMANDS:",
        "  rpn    - Switch to RPN mode",
        "  std    - Switch to standard mode",
        "  clear  - Clear display and stack",
        "  help   - Show this help",
        "  q      - Quit calculator",
        "",
        divider(50)
      ]
  end
end
