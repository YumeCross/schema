test "parse numeric schema" {
  let s = @lib.parse!(
    { "type": "number", "minimum": 1, "exclusiveMaximum": 12 },
  )
  let result : @lib.Schema = {
    typ: @utils.Left("number"),
    keywords: @lib.of([@lib.ExclusiveMaximum(12), @lib.Minimum(1)]),
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
