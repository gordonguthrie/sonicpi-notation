defmodule NotationCompiler.ProcessFilesTest do
  use ExUnit.Case
  import NotationCompiler.ProcessFiles, only: [parse_TEST: 1]

  describe "basic tests" do
    test "basic melody test" do
      input = "choon = /cd.f| a a|  e /"
      exp = :bingo
      run(input, exp)
    end

    test "basic beat test" do
      input = "kick = /...x|.x.X|  X /"
      exp = :bingo
      run(input, exp)
    end
  end

  describe "marked tests" do
    test "marked melody test" do
      input = "choon = /cd.f| a a|  é /"
      exp = :bingo
      run(input, exp)
    end

    test "marked beat test" do
      input = "kick = /...ẍ|.x.Ẋ|  X /"
      exp = :bingo
      run(input, exp)
    end
  end

  describe "basic melodies with keys" do
    test "basic melody with key 1" do
      input = "choon = /cd.f| A E|  e /C"
      exp = :bingo
      run(input, exp)
    end

    test "basic melody with key 2" do
      input = "choon = /cd.f| A E|  e /Em"
      exp = :bingo
      run(input, exp)
    end

    test "basic melody with key 3" do
      input = "choon = /cd.f| A E|  e /F4"
      exp = :bingo
      run(input, exp)
    end

    test "basic melody with key 4" do
      input = "choon = /cd.f| A E|  e /Gm4"
      exp = :bingo
      run(input, exp)
    end
  end

  describe "combo tests" do
    test "all in one" do
      input = "choon = /cd.f| A E|  é /Gm3\nkick = /...ẍ|.x.Ẋ|  X /"
      exp = :bingoreelae
      run(input, exp)
    end
  end

  describe "error tests" do
    test "junk 1" do
      input = "dffsd"
      exp = {:error, [{"not an expression", "dffsd"}]}
      run(input, exp)
    end

    test "looks like it might work junk" do
      input = "/...x|.x.X| eX /"
      exp = {:error, [{"not an expression", "/...x|.x.X| eX /"}]}
      run(input, exp)
    end

    test "no variable name" do
      input = "= /...x|.x.X| eX /"
      exp = {:error, [{"no variable name", "= /...x|.x.X| eX /"}]}
      run(input, exp)
    end

    test "invalid beat input" do
      input = "kick = /...x|.x.X| eX /"
      exp = :bingorama
      run(input, exp)
    end

    test "invalid melody test" do
      input = "choon = /cd.f|ha a|  e /"
      exp = :bingoff
      run(input, exp)
    end
  end

  describe "blank line and comment tests" do
    test "blank lines return unchanged" do
      input = " \n \r\n   \r  "
      exp = {:ok, ["", "", ""]}
      run(input, exp)
    end

    test "comment returns unchanged" do
      input = "# howdy doody \n   ## yeah boy"
      exp = {:ok, ["# howdy doody", "## yeah boy"]}
      run(input, exp)
    end
  end

  describe "duff input tests" do
    test "raises error for non-binary input" do
      assert_raise FunctionClauseError, fn ->
        parse_TEST(123)
      end
    end

    test "handles empty file" do
      input = ""
      exp = ""
      run(input, exp)
    end
  end

  defp run(input, exp) do
    got = parse_TEST(input)
    assert got == exp
  end
end
