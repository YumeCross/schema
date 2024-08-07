test "parse_number_schema" {
  @lib.parse!({ "type": "number", "minimum": 0, "maximum": 42 }) |> ignore
}
