test "validate_number" {
  @test.eq!(
    @lib.parse!({ "type": "number", "maximum": 42.0 }).validate(12),
    true,
  )
}

test "validate_string" {
  let sch = @lib.parse!({ "type": "string", "minLength": 5, "maxLength": 12 })
  @test.eq!(sch.validate(233), false)
  @test.eq!(sch.validate("Hello World"), true)
}
