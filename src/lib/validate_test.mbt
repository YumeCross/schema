test "validate_array" {
  let sch1 = @lib.parse!({ "type": "array", "minItems": 2, "maxItems": 3 })
  assert_eq!(sch1.validate([1, 2]), true)
  assert_eq!(sch1.validate([1, 2, 3, 4, 5]), false)
  let sch2 = @lib.parse!(
    {
      "type": "array",
      "items": [{ "const": 1 }, { "type": "number" }, { "type": "number" }],
    },
  )
  assert_eq!(sch2.validate([1, 2, 3]), true)
  assert_eq!(sch2.validate([2, 1, 2]), false)
  let sch3 = @lib.parse!({ "type": "array", "items": [{ "type": "string" }] })
  assert_eq!(sch3.validate(["test"]), true)
  assert_eq!(sch3.validate([2, 1]), false)
}

test "validate_number" {
  let schema = @lib.parse!(
    {
      "$id": "example",
      "type": "object",
      "properties": {
        "limited_number": { "type": "number", "minimum": 0, "maximum": 42 },
      },
    },
  )
  assert_eq!(schema.validate({ "limited_number": 23 }), true)
  assert_eq!(schema.validate({ "limited_number": 43 }), false)
}

test "validate_object" {
  let sch1 = @lib.parse!(
    {
      "type": "object",
      "properties": {
        "a": { "type": "number", "const": 42 },
        "b": { "type": "string", "const": "hello" },
      },
    },
  )
  assert_eq!(sch1.validate({ "a": 42, "b": "hello" }), true)
  assert_eq!(sch1.validate({ "a": 42, "b": "what" }), false)
  let sch2 = @lib.parse!(
    {
      "type": "object",
      "properties": {
        "test": { "type": "string", "enum": ["test-1", "variant-2"] },
      },
    },
  )
  assert_eq!(sch2.validate({ "test": "test-1" }), true)
  assert_eq!(sch2.validate({ "test": "variant-2" }), true)
}

test "validate_string" {
  let sch = @lib.parse!({ "type": "string", "minLength": 5, "maxLength": 12 })
  assert_eq!(sch.validate(233), false)
  assert_eq!(sch.validate("Hello World"), true)
}
