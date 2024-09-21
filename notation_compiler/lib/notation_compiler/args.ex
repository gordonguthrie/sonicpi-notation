defmodule NotationCompiler.Args do
  ### Purpose

  ## A standard Elixir library has collected and marshalled all the arguments.
  ## This module verifies them and ensures that the set of arguments passed
  ## are coherent.

  ### Data Structures

  ## This arguments structure is populated when the CLI is called and
  ## is then passed around the various arguments

  ## When the inputs are validated, any errors are written to the `errors` key
  ## The consumer of this argument struct checks if it is error free

  defstruct inputdir: nil,
            outputdir: nil,
            excludes: nil,
            list_files: false,
            help: false,
            translatefile: nil,
            errors: []

  #### Public API

  ## Three simple self-explanatory functions.

  def parse_args(args) do
    acc = %NotationCompiler.Args{}
    parse_args(args, acc)
  end

  def print_help() do
    lines = [
      "Help",
      "",
      "notation compiler is a script that converts ascii musical notation into sonic-pi code",
      "",
      "Options:",
      "-h --help       takes no argument",
      "                prints this message",
      "                (optional)",
      "",
      "-e --exclude    takes 1 argument",
      "                which path to and name of an exclude file",
      "                which contains a list of modules to exclude",
      "                one per line, path relative to the directory this script runs in",
      "                exclude files can be generated with the -l --list option.",
      "                This supports simple directory wildcards of the form 'path/to/a/dir/*",
      "                (optional - default .notation_compiler.exclude in the current directory)",
      "",
      "-i --inputdir   takes 1 argument",
      "                the root directory of the code",
      "                defaults to the current directory",
      "",
      "-l --list       takes no arguments",
      "                doesn't process the files, just prints them",
      "                (optional)",
      "",
      "-o --outputdir  takes 1 argument",
      "                the directory to output the sonic-pi code",
      "                defaults to the current directory",
      "",
      "-t --translate  takes 1 arguement",
      "                the name of a file which contains the translations",
      "                without this the emphatics will be returned as accent names",
      "                like grave, acute or circumflex",
      "                (optional)",
      "",
      "Either the inputdir or the outputdir must be set explicitly",
      "",
      "Examples:",
      "./notation_compiler -o /some/dir/for/output",
      "./notation_compiler --outputdir /some/dir/for/output",
      "./notation_compiler -i /some/dir/for/input -o /some/dir/for/output",
      "./notation_compiler --help",
      "./notation_compiler -i /some/dir/for/input -l",
      ""
    ]

    for x <- lines, do: IO.puts(x)
  end

  def print_errors(parsedargs) do
    IO.puts("script did not run because of the following errors:")
    for x <- parsedargs.errors, do: IO.puts(x)
    IO.puts("")
  end

  #### Private Functions

  ## `parse_args` places the inputs into the data structure
  ## when the arguments have been consumed it calles `validate` on the data structure

  defp parse_args([], args), do: validate(args)
  defp parse_args(["-h" | t], args), do: parse_args(t, %NotationCompiler.Args{args | help: true})

  defp parse_args(["--help" | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | help: true})

  defp parse_args(["-e", e | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | excludes: e})

  defp parse_args(["--exclude", e | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | excludes: e})

  defp parse_args(["-i", i | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | inputdir: i})

  defp parse_args(["--inputdir", i | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | inputdir: i})

  defp parse_args(["-l" | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | list_files: true})

  defp parse_args(["--list" | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | list_files: true})

  defp parse_args(["-o", o | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | outputdir: o})

  defp parse_args(["--outputdir", o | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | outputdir: o})

  defp parse_args(["-t", o | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | translatefile: o})

  defp parse_args(["--translate", o | t], args),
    do: parse_args(t, %NotationCompiler.Args{args | translatefile: o})

  defp parse_args([h | t], args) do
    error =
      case h do
        <<"-", _rest::binary>> -> "unknown option #{h}"
        _ -> "unknown action #{h}"
      end

    newerrors = args.errors ++ [error]
    parse_args(t, %NotationCompiler.Args{args | errors: newerrors})
  end

  ## The validate pipeline places all and any errors on the `errors` key
  ## The reason for this is to avoid the irritating **fix and run again** problem
  ## If the user makes multiple mistakes in their invocation they should be told
  ## all of them and not just the first

  defp validate(args) do
    args
    |> validate_usage
    |> validate_paths
    |> validate_excludes
    |> validate_translatefile
  end

  defp validate_usage(args) do
    case {args.inputdir, args.outputdir} do
      {nil, nil} ->
        newerrors = ["both inputdir and outputdir can't be unspecified" | args.errors]
        %{args | errors: newerrors}

      {nil, _} ->
        %{args | inputdir: "./"}

      {_, nil} ->
        %{args | outputdir: "./"}

      {_, _} ->
        args
    end
  end

  defp validate_paths(%{errors: []} = args) do
    inputDirIsDir = File.dir?(args.inputdir)
    outputDirIsDir = File.dir?(args.outputdir)

    case {inputDirIsDir, outputDirIsDir} do
      {true, true} ->
        args

      {true, false} ->
        newerrors = ["output dir #{args.outputdir} is not a directory" | args.errors]
        %{args | errors: newerrors}

      {false, true} ->
        newerrors = ["input dir #{args.inputdir} is not a directory" | args.errors]
        %{args | errors: newerrors}

      {false, false} ->
        newerrors = [
          "neither input dir#{args.inputdir} nor output dir #{args.outputdir} is a directory"
          | args.errors
        ]

        %{args | errors: newerrors}
    end
  end

  defp validate_paths(args), do: args

  defp validate_excludes(%{excludes: e} = args) when e == nil do
    case File.exists?("./.notation_compiler.exclude") do
      true ->
        excludes = read_file("./.notation_compiler.exclude")
        %{args | excludes: excludes}

      false ->
        %{args | excludes: []}
    end
  end

  defp validate_excludes(%{excludes: e, errors: errs} = args) do
    case File.exists?(e) do
      true ->
        excludes = read_file(e)
        %{args | excludes: excludes}

      false ->
        newerrs = ["exclude file doesn't exist: #{e}" | errs]
        %{args | errors: newerrs}
    end
  end

  defp validate_translatefile(%{translatefile: t} = args) when t == nil do
    case File.exists?("./.notation_compiler.translate") do
      true ->
        translatefile = read_file("./.notation_compiler.translate")
        %{args | translatefile: translatefile}

      false ->
        %{args | translatefile: []}
    end
  end

  defp validate_translatefile(%{translatefile: t, errors: errs} = args) do
    case File.exists?(t) do
      true ->
        translatefile = read_file(t)
        %{args | translatefile: translatefile}

      false ->
        newerrs = ["translate file doesn't exist: #{t}" | errs]
        %{args | errors: newerrs}
    end
  end

  defp read_file(file) do
    {:ok, contents} = File.read(file)
    String.split(contents, "\n")
  end
end
