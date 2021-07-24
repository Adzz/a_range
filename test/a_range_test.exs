defmodule ARangeTest do
  use ExUnit.Case
  doctest ARange

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

  describe "new/1" do
    test "current value is set to the start value" do
      letters = ARange.new("a", "b", Letter)
      assert letters == %ARange{current_value: "a", end: "b", type: Letter, start: "a"}
    end

    test "map input" do
      letters = ARange.new(%{start: "a", end: "b", type: Letter})
      assert letters == %ARange{current_value: "a", end: "b", type: Letter, start: "a"}
    end
  end

  describe "next/1" do
    test "we can step to the next step" do
      letters = ARange.new("a", "b", Letter)
      next = ARange.next(letters)
      assert next == %ARange{current_value: "b", end: "b", start: "a", type: Letter}
    end

    test "stepping past the end is a no op" do
      letters = ARange.new("a", "b", Letter)
      next = ARange.next(letters) |> ARange.next() |> ARange.next() |> ARange.next()
      assert next == %ARange{current_value: "b", end: "b", start: "a", type: Letter}
    end
  end

  describe "previous/1" do
    test "we can step to the previous step" do
      letters = ARange.new("a", "z", Letter)
      previous = ARange.next(letters) |> ARange.next() |> ARange.previous()
      assert previous == %ARange{current_value: "b", end: "z", start: "a", type: Letter}
    end

    test "stepping past the end is a no op" do
      letters = ARange.new("a", "b", Letter)
      previous = ARange.previous(letters) |> ARange.previous() |> ARange.previous()
      assert previous == %ARange{current_value: "a", end: "b", start: "a", type: Letter}
    end
  end

  describe "included?/2" do
    test "returns true if the value is in the range" do
      letters = ARange.new("a", "z", Letter)
      assert ARange.included?(letters, "a")
    end
  end

  describe "current_value/1" do
    test "returns what can be considered the current value" do
      letters = ARange.new(%{start: "a", end: "b", type: Letter})
      assert letters == %ARange{current_value: "a", end: "b", type: Letter, start: "a"}
      next = ARange.next(letters)
      assert next == %ARange{current_value: "b", end: "b", type: Letter, start: "a"}
    end
  end

  describe "count/1" do
    test "returns the number of elements in the range, according to our type" do
      letters = ARange.new(%{start: "a", end: "b", type: Letter})
      assert ARange.count(letters) == 2
    end
  end

  describe "Enumerable is implemented for ARange" do
    test "count/1" do
      letters = ARange.new(%{start: "a", end: "z", type: Letter})
      assert Enum.count(letters) == 26

      letters = ARange.new(%{start: "z", end: "a", type: Letter})
      assert Enum.count(letters) == 26

      letters = ARange.new(%{start: "a", end: "a", type: Letter})
      assert Enum.count(letters) == 1
    end
  end

  describe "member?/2" do
    test "returns true if the value is a member" do
      letters = ARange.new(%{start: "a", end: "z", type: Letter})
      assert Enum.member?(letters, "b")
      # I guess this means our implementation loops, but like we may be missing loads
      # of unicode values?
      letters = ARange.new(%{start: "z", end: "a", type: Letter})
      refute Enum.member?(letters, "b")

      letters = ARange.new(%{start: "a", end: "a", type: Letter})
      assert Enum.member?(letters, "a")
    end
  end

  describe "reduce/3" do
    test "reduce works" do
      letters = ARange.new(%{start: "a", end: "g", type: Letter})
      reversed = Enum.reduce(letters, [], fn l, acc -> [l | acc] end)
      assert reversed == ["g", "f", "e", "d", "c", "b", "a"]
    end
  end
end
