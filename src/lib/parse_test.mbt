test "parse numeric schema" {
  let s = @lib2.parse!(
    { "type": "number", "minimum": 1, "exclusiveMaximum": 12 },
  )
  let result : @lib2.Schema = {
    typ: @utils.Left("number"),
    keywords: @lib2.of([@lib2.ExclusiveMaximum(12), @lib2.Minimum(1)]),
  }
  assert_eq!(s, result)
}

test "parse string-specific schema" {
  let s = @lib2.parse!({ "type": "string", "maxLength": 12, "minLength": 6 })
  let result : @lib2.Schema = {
    typ: @utils.Left("string"),
    keywords: @lib2.of([@lib2.MaxLength(12), @lib2.MinLength(6)]),
  }
  assert_eq!(s, result)
}
