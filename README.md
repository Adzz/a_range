# ARange

WIP - don't use.

Ranges in elixir have some limitations. Right now they are only for integer values and you can't make ranges for letters say. This library lets you define any arbitrary range.

### How it works

Ranges can be thought of as streams of values that start at some value, progress to a next value and halt at a final value. We need to be able to step forwards and backwards through a range and determine if a given value exists withing a range.

You can optionally provide an included? function that accepts a value and determines if the value is in the range being created. This allows optimizations that mean you don't have to iterate through the range to determine membership. If not provided it will default to iterating through the range.

### Limitations

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


### Examples

```elixir
one_to_ten = ARange.new(1, 10, fn x -> x + 1 end, fn x -> x >= 1 && x <= 10 && is_integer(x) end)

included? = fn letter ->
  with [code_point] <- String.to_charlist(letter) do
    code_point <= ?z && code_point >= ?a && rem(code_point - ?a, 1) == 0
  else
    _ -> false
  end
end

next_letter = fn letter ->
  [code_point] = String.to_charlist(letter)
  <<code_point + 1>>
end

a_to_b = ARange.new("a", "b", next_letter, included?)
```

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

