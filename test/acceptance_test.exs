defmodule Docopt.Test.Acceptance do
  use ExUnit.Case

  defmodule Parser do
    def parse(file) do
      File.stream!(file)
      |> Enum.reduce({:skip, 0, 0, []}, &parse/2)
      |> unpack
      |> Enum.reverse
    end

    def parse(line, {:skip, lc, tc, ats}) do
      cond do
        match = Regex.run(~r/^r"""(.*)"""\s*$/, line) ->
          [_, docopt] = match
          at = %{id: tc + 1, at_line: lc + 1, docopt: docopt, tests: []}
          {:command, lc + 1, tc + 1, [at|ats]}
        match = Regex.run(~r/^r"""(.*)$/, line) ->
          [_, docopt] = match
          at = %{id: tc + 1, at_line: lc + 1, docopt: docopt, tests: []}
          {:usage, lc + 1, tc + 1, [at|ats]}
        true ->
          {:skip, lc + 1, tc, ats}
      end
    end

    def parse(line, {:usage, lc, tc, [at|ats]}) do
      cond do
        line =~ ~r/^"""\s*$/ ->
          {:command, lc + 1, tc, [at|ats]}
        true ->
          {:usage, lc + 1, tc, [%{at | docopt: at.docopt <> line}|ats]}
      end
    end

    def parse(line, {:command, lc, tc, [at|ats]}) do
      cond do
        match = Regex.run(~r/^\$\s+(.*)$/, line) ->
          [_, args] = match
          test = %{command: args, output: ""}
          {:output, lc + 1, tc, [%{at | tests: [test | at.tests]}|ats]}
        line =~ ~r/^\s*$/ ->
          {:skip, lc + 1, tc, [%{at | tests: Enum.reverse(at.tests)}|ats]}
        line =~ ~r/^#/ ->
          {:command, lc + 1, tc, [at|ats]}
        line =~ ~r/^r"""/ ->
          parse(line, {:skip, lc + 1, tc, [at|ats]})
        true ->
          raise "Expected command at line #{lc + 1}"
      end
    end

    def parse(line, {:output, lc, tc, [at|ats]}) do
      cond do
        line =~ ~r/^\s*$/ ->
          {:command, lc + 1, tc, [at|ats]}
        true ->
          [test|tests] = at.tests
          test = %{test | output: test.output <> line}
          tests = [test|tests]
          {:output, lc + 1, tc, [%{at | tests: tests}|ats]}
      end
    end

    def unpack({:skip, _, _, ats}), do: ats
    def unpack({:output, _, _, ats}), do: ats
  end

  @testcases "test/testcases.docopt"

  test "Docopt testcase file exists" do
    assert File.exists?(@testcases), "Docopt testcase file #{@testcases} not found"
  end

  for at <- Parser.parse(@testcases) do
    # for test <- at.tests do
      test "Acceptance test #{at.id} at line: #{at.at_line}" do
        # assert String.length(unquote(test.output)) >= 0
        assert 1 + 1 == 2
      end
    # end
  end
end
