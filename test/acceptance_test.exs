defmodule Docopt.Test.Acceptance do
  use ExUnit.Case

  @testcases "test/testcases.docopt"

  test "Docopt testcase file exists" do
    assert File.exists?(@testcases), "Docopt testcase file #{@testcases} not found"
  end
end
