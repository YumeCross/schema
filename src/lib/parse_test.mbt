test "parse numeric schema" {
  let s = @lib.parse!(
    { "type": "number", "minimum": 1, "exclusiveMaximum": 12 },
  )
  let result : @lib.Schema = {
    typ: @utils.Left("number"),
    keywords: @lib.of([@lib.Minimum(1), @lib.ExclusiveMaximum(12),]),
  }
  assert_eq!(s, result)
}

test "parse string-specific schema" {
  let s = @lib.parse!({ "type": "string", "maxLength": 12, "minLength": 6 })
  let result : @lib.Schema = {
    typ: @utils.Left("string"),
    keywords: @lib.of([@lib.MaxLength(12), @lib.MinLength(6)]),
  }
  assert_eq!(s, result)
}

test "parse object-specific schema" {
  let s = @lib.parse!(
    {
      "type": "object",
      "properties": { "foo": { "type": "number" } },
      "required": ["foo", "bar"],
    },
  )
  let result : @lib.Schema = {
    typ: @utils.Left("object"),
    keywords: @lib.of(
      [
        @lib.Properties({ "foo": { typ: @utils.Left("number"), keywords: {} } }),
        @lib.Required(["foo", "bar"]),
      ],
    ),
  }
  assert_eq!(s, result)
}

test "parse array-specific schema" {
  let s = @lib.parse!({ "type": "array", "items": { "type": "string" } })
  let result : @lib.Schema = {
    typ: @utils.Left("array"),
    keywords: @lib.of([@lib.Items({ typ: @utils.Left("string"), keywords: {} })]),
  }
  assert_eq!(s, result)
}
