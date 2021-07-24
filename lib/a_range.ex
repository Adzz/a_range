defmodule ARange do
  @moduledoc """
  """

  defstruct [:start, :end, :type, :current_value]
  @type t :: %__MODULE__{}

  @doc """
  Gets given the current value and should return whatever should be considered the next value.
  """
  @callback next(any()) :: any()

  @doc """
  Gets given the current value and should return whatever should be considered the previous value.
  """
  @callback previous(any()) :: any()

  @doc """
  Accepts any given value and should return whether or not the value exists in the range
  """
  @callback included?(any(), any(), any()) :: any()

  @doc """
  Accepts the first and last value in the range and returns how many elements are in the given range
  """
  @callback count(any(), any()) :: any()

  @doc """
  Accepts the a starting value and a count of total elements and should return a list of count
  elements taken from the range (starting at the starting value).
  """
  @callback subset(integer(), integer()) :: any()

  @doc """
  """
  def new(start, end_value, type) do
    %__MODULE__{
      start: start,
      end: end_value,
      type: type,
      current_value: start
    }
  end

  def new(%{start: start, end: _end_value, type: _type} = args) do
    struct!(__MODULE__, Map.put(args, :current_value, start))
  end

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

  # We could also add disjoint?/2 like Range has in Elixir.

  defimpl Enumerable do
    def count(range) do
      {:ok, ARange.count(range)}
    end

    def member?(range, value) do
      {:ok, ARange.included?(range, value)}
    end

    def reduce(range, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(range, &1, fun)}
    end

    def reduce(_range, {:halt, acc}, _fun), do: acc

    def reduce(range, {:cont, acc}, fun) do
      current = ARange.current_value(range)

      if current == range.end do
        {:done, fun.(current, acc) |> elem(1)}
      else
        new_acc = fun.(current, acc)
        reduce(ARange.next(range), new_acc, fun)
      end
    end

    def slice(range) do
      {:ok, ARange.count(range), fn start, length -> range.type.subset(start, length) end}
    end
  end
end
