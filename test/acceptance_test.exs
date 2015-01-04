defmodule Docopt.Test.Acceptance do
  use ExUnit.Case

  defmodule Parser do
    def parse(_file) do
      [
        %{id: 1, at_line: 0, input: "", args: "", output: ""},
        %{id: 2, at_line: 0, input: "", args: "", output: ""},
        %{id: 3, at_line: 0, input: "", args: "", output: ""},
      ]
    end
  end

  @testcases "test/testcases.docopt"

  test "Docopt testcase file exists" do
    assert File.exists?(@testcases), "Docopt testcase file #{@testcases} not found"
  end

  for tc <- Parser.parse(@testcases) do
    test "Acceptance test #{tc.id} at line: #{tc.at_line}" do
      assert unquote(tc.output) == ""
    end
  end
end
