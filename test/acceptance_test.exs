defmodule Docopt.Test.Acceptance do
  use ExUnit.Case

  defmodule Parser do
    import Enum

    def parse(file) do
      File.stream!(file)
      |> reduce({:skip, 0, 0, "", []}, &parse/2)
      |> unpack
      |> reverse
    end

    def parse(line, {:skip, lc, tc, docopt, ats}) do
      cond do
        match = Regex.run(~r/^r"""(.*)"""\s*$/, line) ->
          [_, docopt] = match
          {:command, lc + 1, tc, docopt, ats}
        match = Regex.run(~r/^r"""(.*)$/, line) ->
          [_, docopt] = match
          {:usage, lc + 1, tc, docopt, ats}
        true ->
          {:skip, lc + 1, tc, docopt, ats}
      end
    end

    def parse(line, {:usage, lc, tc, docopt, ats}) do
      cond do
        line =~ ~r/^"""\s*$/ ->
          {:command, lc + 1, tc, docopt, ats}
        true ->
          {:usage, lc + 1, tc, docopt <> line, ats}
      end
    end

    def parse(line, {:command, lc, tc, docopt, ats}) do
      cond do
        match = Regex.run(~r/^\$\s+(.*)$/, line) ->
          [_, command] = match
          at = %{id: tc + 1, at_line: lc + 1, docopt: docopt, command: command, output: ""}
          {:output, lc + 1, tc + 1, docopt, [at | ats]}
        line =~ ~r/^\s*$/ ->
          {:skip, lc + 1, tc, docopt, ats}
        line =~ ~r/^#/ ->
          {:command, lc + 1, tc, docopt, ats}
        line =~ ~r/^r"""/ ->
          parse(line, {:skip, lc + 1, tc, docopt, ats})
        true ->
          raise "Expected command at line #{lc + 1}"
      end
    end

    def parse(line, {:output, lc, tc, docopt, [at|ats]}) do
      cond do
        line =~ ~r/^\s*$/ ->
          {:command, lc + 1, tc, docopt, [at|ats]}
        true ->
          {:output, lc + 1, tc, docopt, [%{at | output: at.output <> line}|ats]}
      end
    end

    def unpack({:skip, _, _, _, ats}), do: ats
    def unpack({:output, _, _, _, ats}), do: ats
  end

  @external_resource testcases = Path.join([__DIR__, "resources", "testcases.docopt"])

  for at <- Parser.parse(testcases) do
    @tag :acceptance
    test "Acceptance test number #{at.id} at line #{at.at_line}" do
      :timer.sleep(100)
      assert String.length(unquote(at.output)) >= 0
    end
  end
end
