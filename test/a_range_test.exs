defmodule ARangeTest do
  use ExUnit.Case
  doctest ARange

  defmodule Letterz do
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
  end

  # If Letterz is a struct then we can use protocols, but we need a way to
  # say "it needs to be a struct with start and end keys". This would also
  # mean the user could sneak in extra info in the type by having extra keys.
  # which is interesting. Vs the quite rigid behaviour approach.
  # ARange.new(%Letterz{start: "a", end: "b"})
  # %ARange{of: %Letterz{start: "a", end: "b"}, current_value: "a"}
  # ARange.of(%Letterz{start: "a", end: "b"})

  describe "new/1" do
    test "current value is set to the start value" do
      letters = ARange.new("a", "b", Letterz)
      assert letters == %ARange{current_value: "a", end: "b", type: Letterz, start: "a"}
    end

    test "map input" do
      letters = ARange.new(%{start: "a", end: "b", type: Letterz})
      assert letters == %ARange{current_value: "a", end: "b", type: Letterz, start: "a"}
    end

    test "you can use a map for the type" do
      type = %{
        next: fn _ -> "b" end,
        previous: fn _ -> "a" end,
        included?: fn _, _, _ -> true end,
        count: fn _ -> 1 end
      }

      letters = ARange.new(%{start: "a", end: "b", type: type})
      assert letters == %ARange{current_value: "a", end: "b", start: "a", type: type}
    end
  end

  describe "next/1" do
    test "we can step to the next step" do
      letters = ARange.new("a", "b", Letterz)
      next = ARange.next(letters)
      assert next == %ARange{current_value: "b", end: "b", start: "a", type: Letterz}
    end

    test "stepping past the end is a no op" do
      letters = ARange.new("a", "b", Letterz)
      next = ARange.next(letters) |> ARange.next() |> ARange.next() |> ARange.next()
      assert next == %ARange{current_value: "b", end: "b", start: "a", type: Letterz}
    end
  end

  describe "previous/1" do
    test "we can step to the previous step" do
      letters = ARange.new("a", "z", Letterz)
      previous = ARange.next(letters) |> ARange.next() |> ARange.previous()
      assert previous == %ARange{current_value: "b", end: "z", start: "a", type: Letterz}
    end

    test "stepping past the end is a no op" do
      letters = ARange.new("a", "b", Letterz)
      previous = ARange.previous(letters) |> ARange.previous() |> ARange.previous()
      assert previous == %ARange{current_value: "a", end: "b", start: "a", type: Letterz}
    end
  end

  describe "included?/2" do
    test "returns true if the value is in the range" do
      letters = ARange.new("a", "z", Letterz)
      assert ARange.included?(letters, "a")
    end
  end

  describe "current_value/1" do
    test "returns what can be considered the current value" do
      letters = ARange.new(%{start: "a", end: "b", type: Letterz})
      assert letters == %ARange{current_value: "a", end: "b", type: Letterz, start: "a"}
      next = ARange.next(letters)
      assert next == %ARange{current_value: "b", end: "b", type: Letterz, start: "a"}
    end
  end

  describe "count/1" do
    test "returns the number of elements in the range, according to our type" do
      letters = ARange.new(%{start: "a", end: "b", type: Letterz})
      assert ARange.count(letters) == 2
    end
  end

  describe "Enumerable is implemented for ARange" do
    test "count/1" do
      letters = ARange.new(%{start: "a", end: "z", type: Letterz})
      assert Enum.count(letters) == 26

      letters = ARange.new(%{start: "z", end: "a", type: Letterz})
      assert Enum.count(letters) == 26

      letters = ARange.new(%{start: "a", end: "a", type: Letterz})
      assert Enum.count(letters) == 1
    end
  end

  describe "member?/2" do
    test "returns true if the value is a member" do
      letters = ARange.new(%{start: "a", end: "z", type: Letterz})
      assert Enum.member?(letters, "b")
      # I guess this means our implementation loops, but like we may be missing loads
      # of unicode values?
      letters = ARange.new(%{start: "z", end: "a", type: Letterz})
      refute Enum.member?(letters, "b")

      letters = ARange.new(%{start: "a", end: "a", type: Letterz})
      assert Enum.member?(letters, "a")
    end
  end

  describe "reduce/3" do
    test "reduce works" do
      letters = ARange.new(%{start: "a", end: "g", type: Letterz})
      reversed = Enum.reduce(letters, [], fn l, acc -> [l | acc] end)
      assert reversed == ["g", "f", "e", "d", "c", "b", "a"]
    end
  end

  describe "slice/1" do
    test "we can get a subset of the range" do
      letters = ARange.new(%{start: "a", end: "g", type: Letterz})
      assert Enum.slice(letters, 2..50) == ["c", "d", "e", "f", "g"]
      assert Enum.slice(letters, 0..1) == ["a", "b"]
      assert Enum.slice(letters, 1..-1) == ["b", "c", "d", "e", "f", "g"]
      assert Enum.slice(letters, -1..-1) == ["g"]
    end
  end

  # Add more tests for the actual Enumerable fns probs.
end
