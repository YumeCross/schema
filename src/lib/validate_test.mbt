test "validate_number" {
  @test.eq!(
    @lib.parse!({ "type": "number", "maximum": 42.0 }).validate(12),
    true,
  )
}

test "validate_object" {
  let sch1 = @lib.parse!(
    {
      "type": "object",
      "properties": {
        "a": {
          "type": "number",
          "const": 42
        },
        "b": {
          "type": "string",
          "const": "hello"
        }
      }
    }
  )
  @test.eq!(sch1.validate({
    {"a": 42, "b": "hello"}
  }), true)
  @test.eq!(sch1.validate({
    {"a": 42, "b": "what"}
  }), false)
  let sch2 = @lib.parse!(
    {
      "type": "object",
      "properties": {
        "test": {
          "type": "string",
          "enum": ["test-1", "variant-2"]
        }
      }
    }
  )
  @test.eq!(sch2.validate({
    {"test": "test-1"}
  }), true)
  @test.eq!(sch2.validate({
    {"test": "variant-2"}
  }), true)
}

test "validate_string" {
  let sch = @lib.parse!({ "type": "string", "minLength": 5, "maxLength": 12 })
  @test.eq!(sch.validate(233), false)
  @test.eq!(sch.validate("Hello World"), true)
}
