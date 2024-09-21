defmodule NotationCompiler.CLI do
  ### Purpose

  ## This module is the actual CLI for the escript

  ## It does 3 things:

  ## * prints the help
  ## * displays the errors when the command is wrongly invoked
  ## * runs the script
  ## ^

  ## It uses the Elixir Standard `Args` library to process the arguments

  alias NotationCompiler.Args
  alias NotationCompiler.Tree
  alias NotationCompiler.ProcessFiles
  alias NotationCompiler.Outputter

  #### Public API

  def main(args) do
    parsedargs = Args.parse_args(args)
    IO.inspect(parsedargs, label: "parsedargs")
    run(parsedargs)
  end

  #### Private Fns
  defp run(parsedargs) when parsedargs.help do
    Args.print_help()
  end

  defp run(parsedargs) when parsedargs.list_files do
    Tree.walk_tree([parsedargs.inputdir], parsedargs.excludes, &ProcessFiles.list_file/1)
    :ok
  end

  defp run(parsedargs) when parsedargs.errors != [] do
    Args.print_errors(parsedargs)
    IO.puts("run ./notation_compiler -h for help")
  end

  defp run(parsedargs) do
    files =
      Tree.walk_tree([parsedargs.inputdir], parsedargs.excludes, &ProcessFiles.process_file/1)

    :ok = Outputter.write_output(files, parsedargs)
    :ok
  end
end
