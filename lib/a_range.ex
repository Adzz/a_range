defmodule ARange do
  @moduledoc """
  Functions to create and work with arbitrary ranges.

  Ranges in elixir have some limitations. Right now they are only for integer values and
  in earlier version of Elixir they would only step by one.

  That meant you couldn't make ranges for letters for example. This library lets you define
  any arbitrary range and have the `Enum` functions work with it automatically.

  ### How it works

  Ranges can be thought of as streams of values that start at some value, progress to a
  next value and halt at a final value. We need to be able to step forwards and backwards
  through a range and determine if a given value exists within a range.

  Conceptually all ranges have a notion of some kind of order - element being before or
  after other elements. We therefore require user defined ranges to implement specific
  functions that allow for the Enumerable protocol to work. These functions can be found
  in the ARange behaviour.

  To create a range you must create a module and implement the ARange behaviour's callbacks.
  See the docs for each callback to understand more about them.

  ### Examples

  The following shows how you can create a Range of English language letters which increment
  by 1 codepoint.

      iex>(defmodule Letter do
      ...>   @behaviour ARange
      ...>   @impl true
      ...>   def next(letter) do
      ...>     [code_point] = String.to_charlist(letter)
      ...>     <<code_point + 1>>
      ...>   end
      ...>   @impl true
      ...>   def previous(letter) do
      ...>     [code_point] = String.to_charlist(letter)
      ...>     <<code_point - 1>>
      ...>   end
      ...>   @impl true
      ...>   def included?(start, end_value, letter) do
      ...>     [start_code_point] = String.to_charlist(start)
      ...>     [end_code_point] = String.to_charlist(end_value)
      ...>     with [code_point] <- String.to_charlist(letter) do
      ...>       code_point <= end_code_point && code_point >= start_code_point &&
      ...>         rem(code_point - start_code_point, 1) == 0
      ...>     else
      ...>       _ -> false
      ...>     end
      ...>   end
      ...>   @impl true
      ...>   def count(start, end_value) do
      ...>     [start_code_point] = String.to_charlist(start)
      ...>     [end_code_point] = String.to_charlist(end_value)
      ...>     if start_code_point <= end_code_point do
      ...>       end_code_point - start_code_point + 1
      ...>     else
      ...>       start_code_point - end_code_point + 1
      ...>     end
      ...>   end
      ...>   @impl true
      ...>   def subset(start, count) do
      ...>     [code_point] = String.to_charlist(start)
      ...>     for point <- code_point..(code_point + count) do
      ...>       point
      ...>     end
      ...>   end
      ...> end)
      ...> letters = ARange.new(%{start: "a", end: "z", type: Letter})
      ...> ARange.next(letters) |> ARange.next() |> ARange.next() |> ARange.current_value()
      "d"
  """

  defstruct [:start, :end, :type, :current_value]
  @type t :: %__MODULE__{}

  @doc """
  Gets given the current value and should return whatever should be considered the next
  value.
  """
  @callback next(any()) :: any()

  @doc """
  Gets given the current value and should return whatever should be considered the
  previous value.
  """
  @callback previous(any()) :: any()

  @doc """
  Accepts any given value and should return whether or not the value exists in the range
  """
  @callback included?(any(), any(), any()) :: any()

  @doc """
  Accepts the first and last value in the range and returns how many elements are in the
  given range
  """
  @callback count(any(), any()) :: any()

  @doc """
  Accepts the a starting value and a count of total elements and should return a list of
  count elements taken from the range (starting at the starting value).
  """
  @callback subset(integer(), integer()) :: any()

  @doc """
  Defines a new ARange struct with the given start and end values. Type should be a module
  that implements the ARange behaviour.
  """
  def new(start, end_value, type) when is_atom(type) do
    %__MODULE__{
      start: start,
      end: end_value,
      type: type,
      current_value: start
    }
  end

  def new(%{start: start, end: _end_value, type: type} = args) when is_atom(type) do
    struct!(__MODULE__, Map.put(args, :current_value, start))
  end

  # def new(%{start: start, end: end_value, type: type} = args) do
  #   %{next: next, previous: previous, included?: included?, count: count, subset: subset}
  # end

  @doc """
  """
  def next(range) do
    current = current_value(range)
    # If we do this we can't have dup values which makes sense for a range I think.
    if current == range.end do
      range
    else
      next_value = range.type.next(current)
      %{range | current_value: next_value}
    end
  end

  @doc """
  """
  def previous(range) do
    current = current_value(range)
    # If we do this we can't have dup values which makes sense for a range I think.
    if current == range.start do
      range
    else
      prev_value = range.type.previous(current)
      %{range | current_value: prev_value}
    end
  end

  @doc """
  """
  def included?(range, value) do
    range.type.included?(range.start, range.end, value)
  end

  @doc """
  """
  def current_value(range) do
    range.current_value
  end

  @doc """
  """
  def count(range) do
    range.type.count(range.start, range.end)
  end

  @doc """
  """
  # duhhhhhh if start index is less than zero subtract
  def subset(range, start_index, count) do
    start_value =
      range.type.at(range.start, range.end, start_index)
      |> IO.inspect(limit: :infinity, label: "")

    range.type.subset(start_value, count)
  end

  # We could also add disjoint?/2 like Range has in Elixir.

  defimpl Enumerable do
    def count(range), do: {:ok, ARange.count(range)}
    def member?(range, value), do: {:ok, ARange.included?(range, value)}

    def reduce(range, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(range, &1, fun)}
    def reduce(_range, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(range, {:cont, acc}, fun) do
      current = ARange.current_value(range)

      if current == range.end do
        case fun.(current, acc) do
          {:cont, acc} -> {:done, acc}
          {:suspend, acc} -> {:suspended, acc, &reduce(range, &1, fun)}
          {:halt, acc} -> {:halted, acc}
        end
      else
        new_acc = fun.(current, acc)
        reduce(ARange.next(range), new_acc, fun)
      end
    end

    def slice(range) do
      slice_fun = fn start, count ->
        ARange.subset(range, start, count)
      end

      {:ok, ARange.count(range), slice_fun}
      # {:error, __MODULE__}
    end
  end
end
