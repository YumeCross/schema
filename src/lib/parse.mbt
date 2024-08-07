pub fn parse(object: @json.JsonValue) -> Schema!ParseError {
  // TODO: Complete
  match object.as_object() {
    Some({
      "type": String("number"),
      "minimum"? : minimum,
      "exclusiveMinimum"? : exclusiveMinimum,
      "maximum"? : maximum,
      "exclusiveMaximum"? : exclusiveMaximum
    }) => {
      let medium = Schema::new("number")
      { ..medium, content: object.as_object().unwrap() }
    }
    Some(_) => {
      raise ParseError(InvalidSchema(""))
    }
    _ => {
      let ty_name = type_name(object)
      raise ParseError(
        InvalidType("Expect a Json object, got \{ty_name}")
      )
    }
  }
}