# ARange

Alpha version - implementation may change.

Ranges in elixir have some limitations. Right now they are only for integer values and you can't make ranges for letters for example. This library lets you define any arbitrary range and have Enum functions work with it automatically.

### How it works

Ranges can be thought of as streams of values that start at some value, progress to a next value and halt at a final value. We need to be able to step forwards and backwards through a range and determine if a given value exists within a range.

Conceptually all ranges have a notion of some kind of order - element being before or after other elements. We therefore require user defined ranges to implement specific functions that allow for the Enumerable protocol to work. These functions can be found in the ARange behaviour.

To create a range you must create a module and implement the ARange behaviour's callbacks:

```elixir
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
```

see the examples below


### Examples

The following shows how you can create a Range of English language letters which increment by 1 codepoint.

```elixir
defmodule Letter do
  @behaviour ARange
  @moduledoc """
  Enables creation of ranges of letters which increment by 1 codepoint.
  """

  @impl true
  def next(letter) do
    [code_point] = String.to_charlist(letter)
    <<code_point + 1>>
  end

  @impl true
  def previous(letter) do
    [code_point] = String.to_charlist(letter)
    <<code_point - 1>>
  end

  @impl true
  def included?(start, end_value, letter) do
    [start_code_point] = String.to_charlist(start)
    [end_code_point] = String.to_charlist(end_value)

    with [code_point] <- String.to_charlist(letter) do
      code_point <= end_code_point && code_point >= start_code_point &&
        rem(code_point - start_code_point, 1) == 0
    else
      _ -> false
    end
  end

  @impl true
  def count(start, end_value) do
    [start_code_point] = String.to_charlist(start)
    [end_code_point] = String.to_charlist(end_value)

    if start_code_point <= end_code_point do
      end_code_point - start_code_point + 1
    else
      start_code_point - end_code_point + 1
    end
  end

  @impl true
  def subset(start, count) do
    [code_point] = String.to_charlist(start)

    for point <- code_point..(code_point + count) do
      point
    end
  end
end

letters = ARange.new("a", "b", Letter)
# Or
letters = ARange.new(%{start: "a", end: "z", type: Letter})
next = ARange.next(letters) |> ARange.next() |> ARange.next() |> ARange.current_value()
Enum.reduce(letters, [], fn l, acc -> [l | acc] end)
```

### Pattern Matching.

Pattern matching on a range is not really possible because you can't execute a function in a guard. Instead you can put it as the first line of your function:

```elixir
def my_fun(value) do
  if ARange.includes?(my_range, value) do
    a_thing()
  else
    another_thing()
  end
end
```

<!--
Can we do some kind of pattern thing with this library...
A standardised pattern to match on for inclusion.
Suppose we should read the paper though.
-->

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `a_range` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:a_range, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/a_range](https://hexdocs.pm/a_range).

