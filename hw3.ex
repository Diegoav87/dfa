# Diego Abdo
# 26/04/2024

defmodule TokenList do
  # Evaluate a string based on an automata
  def evaluate_3(automata, string) do
    eval_dfa(String.graphemes(string), automata, [], [])
  end

  # The automata argument is expressed as
  # {delta, accept, q0}
  # Return the found tokens when the evaluated string is empty
  def eval_dfa([], {_delta, accept, state}, tokens, current) do
    if Enum.member?(accept, state) do
      if state == :space do
        Enum.reverse(tokens)
      else
        Enum.reverse([{state, Enum.join(Enum.reverse(current))} | tokens])
      end
    else
      false
    end
  end

  # Use the transition function to evaluate the current character and get the next state
  def eval_dfa([char | tail], {delta, accept, state}, tokens, current) do
    [new_state, found] = delta.(state, char)

    if found == false do
      if char == " " do
        eval_dfa(tail, {delta, accept, new_state}, tokens, current)
      else
        eval_dfa(tail, {delta, accept, new_state}, tokens, [char | current])
      end
    else
      if char == " " do
        eval_dfa(
          tail,
          {delta, accept, new_state},
          [{found, Enum.join(Enum.reverse(current))} | tokens],
          []
        )
      else
        eval_dfa(
          tail,
          {delta, accept, new_state},
          [{found, Enum.join(Enum.reverse(current))} | tokens],
          [char]
        )
      end
    end
  end

  # Transition function
  def delta_arithmetic(state, char) do
    case state do
      :start ->
        cond do
          is_sign(char) -> [:sign, false]
          is_digit(char) -> [:int, false]
          is_alpha(char) -> [:var, false]
          char == "_" -> [:var, false]
          char == "(" -> [:par_open, false]
          char == " " -> [:space, false]
          true -> [:fail, false]
        end

      :space ->
        cond do
          char == " " -> [:space, false]
          is_digit(char) -> [:int, false]
          is_operator(char) -> [:oper, false]
          is_alpha(char) -> [:var, false]
          char == "(" -> [:par_open, false]
          char == ")" -> [:par_close, false]
          char == "_" -> [:var, false]
        end

      :par_open ->
        cond do
          is_digit(char) -> [:int, :par_open]
          is_alpha(char) -> [:var, :par_open]
          char == "_" -> [:var, :par_open]
          char == " " -> [:space, :par_open]
          true -> [:fail, false]
        end

      :var ->
        cond do
          is_digit(char) -> [:var, false]
          is_alpha(char) -> [:var, false]
          char == "_" -> [:var, false]
          is_operator(char) -> [:oper, :var]
          char == ")" -> [:par_close, :var]
          char == " " -> [:space, :var]
          true -> [:fail, false]
        end

      :int ->
        cond do
          is_digit(char) -> [:int, false]
          is_operator(char) -> [:oper, :int]
          is_exp(char) -> [:e, false]
          char == "." -> [:dot, false]
          char == ")" -> [:par_close, :int]
          char == " " -> [:space, :int]
          true -> [:fail, false]
        end

      :par_close ->
        cond do
          is_operator(char) -> [:oper, :par_close]
          char == " " -> [:space, :par_close]
          true -> [:fail, false]
        end

      :e ->
        cond do
          is_digit(char) -> [:exp, false]
          is_sign(char) -> [:sign_e, false]
          true -> [:fail, false]
        end

      :sign_e ->
        cond do
          is_digit(char) -> [:exp, false]
          true -> [:fail, false]
        end

      :exp ->
        cond do
          is_digit(char) -> [:exp, false]
          is_operator(char) -> [:oper, :exp]
          char == ")" -> [:par_close, :exp]
          char == " " -> [:space, :exp]
          true -> [:fail, false]
        end

      :oper ->
        cond do
          is_sign(char) -> [:sign, :oper]
          is_digit(char) -> [:int, :oper]
          is_alpha(char) -> [:var, :oper]
          char == "_" -> [:var, :oper]
          char == "(" -> [:par_open, :oper]
          char == " " -> [:space, :oper]
          true -> [:fail, false]
        end

      :sign ->
        cond do
          is_digit(char) -> [:int, false]
          true -> [:fail, false]
        end

      :dot ->
        cond do
          is_digit(char) -> [:float, false]
          true -> [:fail, false]
        end

      :float ->
        cond do
          is_digit(char) -> [:float, false]
          is_operator(char) -> [:oper, :float]
          is_exp(char) -> [:e, false]
          char == ")" -> [:par_close, :float]
          char == " " -> [:space, :float]
          true -> [:fail, false]
        end

      :fail ->
        [:fail, false]
    end
  end

  def is_digit(char) do
    Enum.member?(String.graphemes("0123456789"), char)
  end

  def is_sign(char) do
    Enum.member?(["+", "-"], char)
  end

  def is_operator(char) do
    Enum.member?(["*", "/", "+", "-", "%", "^", "="], char)
  end

  def is_exp(char) do
    Enum.member?(["E", "e"], char)
  end

  def is_alpha(char) do
    lowercase = ?a..?z |> Enum.map(&<<&1::utf8>>)
    uppercase = ?A..?Z |> Enum.map(&<<&1::utf8>>)
    Enum.member?(lowercase ++ uppercase, char)
  end

  def arithmetic_lexer(string) do
    evaluate_3(
      {&TokenList.delta_arithmetic/2, [:int, :float, :exp, :var, :par_close, :space], :start},
      string
    )
  end
end
