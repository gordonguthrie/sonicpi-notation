defmodule NotationCompiler.ProcessFiles do
  ### Purpose

  ## this module provides functions to be passed into the tree walker
  ## to process the files it finds

  ## It does two things:

  ## * simply list the files
  ## * compile them into ruby

  @empty_accumulator []

  ### Public API

  def list_file(file) do
    ext = Path.extname(file)

    case ext do
      ".spn" -> IO.puts(file)
      _ -> :ok
    end
  end

  def process_file(file) do
    ext = Path.extname(file)

    case ext do
      ".spn" ->
        {:ok, bin} = File.read(file)
        {file, parse(bin)}

      _ ->
        []
    end
  end

  ## Functions exposed for unit test

  # tests are easier to read/write as strings not binaries
  def parse_TEST(bin) when is_binary(bin) do
    parse(bin)
  end

  ## Private functions

  defp parse(<<>>), do: <<>>

  defp parse(bin) when is_binary(bin) do
    lines = for s <- String.split(bin, "\n"), do: String.trim(s)
    ret = parse_lines(lines, @empty_accumulator, @empty_accumulator)
    IO.inspect(ret, label: "parse returns")
  end

  defp parse_lines([], [], acc), do: {:ok, Enum.reverse(acc)}
  defp parse_lines([], errs, _acc), do: {:error, List.flatten(Enum.reverse(errs))}
  defp parse_lines(["" = h | t], errs, acc), do: parse_lines(t, errs, [h | acc])
  defp parse_lines(["#" <> _ = h | t], errs, acc), do: parse_lines(t, errs, [h | acc])

  defp parse_lines([h | t], errs, acc) do
    IO.inspect(h, label: "in parse_lines, h is")

    {newacc, newerrs} =
      case parse_code(h) do
        {var, code, comment} ->
          IO.puts("code parsed")
          ruby = make_ruby(code)

          newa =
            case comment do
              nil -> var <> "=" <> ruby <> "\n"
              _ -> var <> "=" <> ruby <> " " <> comment <> "\n"
            end

          IO.inspect(newa, label: "in parser lines newa is")
          {[newa | acc], errs}

        {:error, err} ->
          {acc, [err | errs]}
      end

    parse_lines(t, newerrs, newacc)
  end

  defp parse_code(code) do
    {body, comment} = get_comment(code)

    case parse_body(body) do
      {:error, e} -> {:error, {e, code}}
      {var, expr} -> {var, expr, comment}
    end
  end

  defp get_comment(code) do
    case String.split(code, "#", parts: 2) do
      [body, comment] -> {body, comment}
      [body] -> {body, nil}
    end
  end

  defp parse_body(body) do
    case String.split(body, "=") do
      ["", _] -> {:error, "no variable name"}
      [var, code] -> {var, code}
      _ -> {:error, "not an expression"}
    end
  end

  defp make_ruby(body) do
    IO.inspect(body, label: "in make ruby, body is")
    stripped = extract_between_slashes(body)
    key = get_key(body)

    IO.inspect(stripped, label: "in make ruby, stripped is")
    IO.inspect(key, label: "in make ruby key is")
    "erko"
  end

  defp get_key(body) do
    key = List.last(String.split(body, "/"))
    IO.inspect(key, label: "Key is")
    key
  end

  defp extract_between_slashes(str) do
    regex = ~r{\/.*\/}
    [[matches]] = Regex.scan(regex, str)
    IO.inspect(matches, label: "in extract_between_slashes, matches is")
    String.trim(matches, "/")
  end
end
