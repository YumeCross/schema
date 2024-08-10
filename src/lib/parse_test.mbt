test "parse_array_schema" {
  @lib.parse!({ "type": "array", "uniqueItems": true }) |> ignore
}

test "parse_number_schema" {
  @lib.parse!({ "type": "number", "minimum": 0, "maximum": 42 }) |> ignore
  @lib.parse!(
    { "type": "number", "exlusiveMinimum": 0, "exclusiveMaximum": 42 },
  )
  |> ignore
}

test "parse_object_schema" {
  @lib.parse!(
    {
      "type": "object",
      "properties": {
        "a": { "type": "number", "const": 42 },
        "b": { "type": "string", "enum": ["test1", "test2"] },
      },
    },
  )
  |> ignore
}

test "parse_string_schema" {
  @lib.parse!(
    { "type": "string", "minLength": 2, "maxLength": 12, "format": "url" },
  )
  |> ignore
}
