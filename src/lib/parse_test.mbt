test "parse_number_schema" {
  @lib.parse!({ "type": "number", "minimum": 0, "maximum": 42 }) |> ignore
}

test "parse_object_schema" {
  @lib.parse!(
    {
      "type": "object",
      "properties": { "a": { "type": "number" }, "b": { "type": "string" } },
    },
  )
  |> ignore
}
