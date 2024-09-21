defmodule NotationCompiler.Outputter do
  ### Purpose

  ## This module is responsible for writing the output of the compilation

  #### Public API

  def write_output([], _args), do: :ok
  # the tree walker will return a null list if it sees a file
  # with a type that it isn't processing, so we skip that
  def write_output([[] | t], args), do: write_output(t, args)

  def write_output([{oldfilename, body} | t], args) do
    case Enum.member?(args.excludes, oldfilename) do
      true ->
        :ok

      false ->
        IO.inspect(body, label: "gotta write body")
    end

    write_output(t, args)
  end

  #### Private Fns

  # 	defp make_write_file(oldfilename, inputdir, outputdir, ext) do
  # 		relative = Path.relative_to(Path.absname(oldfilename), Path.absname(inputdir))
  # 		old = Path.join([outputdir, relative])
  # 		root = Path.rootname(old)
  # 		Enum.join([root, ".", ext])
  # 	end
end
