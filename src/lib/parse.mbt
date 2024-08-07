fn check(
  member : String,
  specified_ty : String,
  map : Map[String, @json.JsonValue]
) -> @json.JsonValue?!ParseError {
  let option = map[member]
  if option.is_empty() {
    return None
  }
  let mut result : Result[Unit, ParseError] = Ok(())
  let value = option.map(
    fn(value) {
      let ty_name = type_name(value)
      if ty_name != specified_ty {
        result = Err(
          ParseError::make_member_type_error(member, specified_ty, ty_name),
        )
      }
      value
    },
  )
  result.unwrap_or_error!()
  value
}

fn parse_array_schema(
  medium : Schema,
  object : Map[String, @json.JsonValue]
) -> Schema!ParseError {
  let constraint = {
    items: (None, None),
    minItems: check!("minItems", "number", object).map_or(
      0, fn(v) { v.as_number().unwrap().reinterpret_as_u64() }
    ),
    maxItems: check!("minItems", "number", object).map(
      fn(v) { v.as_number().unwrap().reinterpret_as_u64() }
    ),
    uniqueItems: check!("uniqueItems", "boolean", object).map_or(
      false, fn(v) { v.as_bool().unwrap() }
    ),
  }
  { ..medium, typed_constraint: ArrayTy(constraint) }
}

fn parse_number_schema(
  medium : Schema,
  object : Map[String, @json.JsonValue]
) -> Schema!ParseError {
  let constraint = {
    minimum: check!("minimum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
    maximum: check!("maximum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
    exclusiveMinimum: check!("exclusiveMinimum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
    exclusiveMaximum: check!("exclusiveMaximum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
  }
  { ..medium, typed_constraint: NumberTy(constraint) }
}

fn parse_string_schema(
  medium : Schema,
  object : Map[String, @json.JsonValue]
) -> Schema!ParseError {
  let constraint = {
    format: check!("format", "string", object).map(
      fn(v) { v.as_string().unwrap() },
    ),
    pattern: check!("pattern", "string", object).map(
      fn(v) { v.as_string().unwrap() },
    ),
    minLength: check!("minLength", "string", object).map_or(
      0,
      fn(v) { v.as_number().unwrap().reinterpret_as_u64() },
    ),
    maxLength: check!("maxLength", "string", object).map(
      fn(v) { v.as_number().unwrap().reinterpret_as_u64() },
    ),
  }
  { ..medium, typed_constraint: StringTy(constraint) }
}

pub fn parse(object : @json.JsonValue) -> Schema!ParseError {
  // TODO: Complete
  match object.as_object() {
    Some(_) => ()
    None => {
      let ty_name = type_name(object)
      raise ParseError(InvalidSchema("Expect a Json object, got \{ty_name}"))
    }
  }
  let map = object.as_object().unwrap()
  match map {
    { "type": "array" } => parse_array_schema!(Schema::new("array"), map)
    { "type": "number" } => parse_number_schema!(Schema::new("number"), map)
    { "type": "string" } => parse_string_schema!(Schema::new("string"), map)
    _ => raise ParseError(
      InvalidSchema("Invalid member 'type', should be one of 'array', 'boolean', 'null', 'number', 'object', 'string'")
      )
  }
}
