module Lsp = Lsp.Lsp_t
let extract_cursor input =
  let cursor_pos = ref (0, 0) in
  String.split_on_char '\n' input
  |> List.mapi
       (fun line_num line ->
         match String.index_opt line '|' with
         | Some column_num ->
            cursor_pos := (line_num, column_num);
            line
            |> String.split_on_char '|'
            |> String.concat ""
         | None -> line
       )
  |> String.concat "\n"
  |> fun f -> (f, !cursor_pos)

let hovered_identifier_test_case file expected =
  let (file, (line, column)) = extract_cursor file in
  let show = function
    | Some(Hover.Ident i) -> i
    | Some(Hover.Qualified (qualifier, ident)) -> qualifier ^ "." ^ ident
    | None -> "None" in
  let actual =
    Hover.hovered_identifier
      Lsp.{ position_line = line; position_character = column } file in
  Lib.Option.equal (=) actual expected ||
    (Printf.printf
       "\nExpected: %s\nActual:   %s\n"
       (show expected)
       (show actual);
     false)

let%test "it finds an identifier" =
  hovered_identifier_test_case
    "f|ilter"
    (Some (Hover.Ident "filter"))

let%test "it ignores hovering over whitespace" =
  hovered_identifier_test_case "filter |" None

let%test "it finds a qualified identifier" =
  hovered_identifier_test_case
    "List.f|ilter"
    (Some (Hover.Qualified ("List", "filter")))
