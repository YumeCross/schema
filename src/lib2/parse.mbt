fn assert_integer!(n : Double) -> Unit!SchemaParseError {
  // TODO: Adjust the assertion logic
  if n - n.to_int().to_double() >= 0.00000001 {
    raise InvalidSchema
  }
}

test "assert integer" {
  assert_ok!(assert_integer?(1))
  assert_err!(assert_integer?(1.2))
  assert_err!(assert_integer?(3.14))
  assert_ok!(assert_integer?(0.3 - 0.1 + 0.8))
}

pub fn parse!(json : Json) -> Schema!SchemaParseError {
  let schema : Schema = { typ: Left(""), keywords: {} }
  match json.value("type") {
    Some(String(str)) => schema.typ = Left(str)
    Some(Array(arr1)) => {
      let arr2 = arr1.map_option(fn(v) { v.as_string() })
      if arr1.length() != arr2.length() {
        raise InvalidSchema
      }
      schema.typ = Right(arr2)
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("enum") {
    Some(Array(arr)) => schema.keywords["enum"] = Keyword::new(Enum(arr))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("const") {
    Some(v) => schema.keywords["const"] = Keyword::new(Const(v))
    None => ()
  }
  match json.value("default") {
    Some(v) => schema.keywords["default"] = Keyword::new(Default(v))
    None => ()
  }
  // Parse numeric keywords
  match json.value("multipleOf") {
    Some(Number(n)) =>
      schema.keywords["multipleOf"] = Keyword::new(MultipleOf(n))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("maximum") {
    Some(Number(n)) => schema.keywords["maximum"] = Keyword::new(Maximum(n))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("exclusiveMaximum") {
    Some(Number(n)) =>
      schema.keywords["exclusiveMaximum"] = Keyword::new(ExclusiveMaximum(n))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("minimum") {
    Some(Number(n)) => schema.keywords["minimum"] = Keyword::new(Minimum(n))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("exclusiveMinimum") {
    Some(Number(n)) =>
      schema.keywords["exclusiveMinimum"] = Keyword::new(ExclusiveMinimum(n))
    None => ()
    _ => raise InvalidSchema
  }
  // Parse string keywords
  match json.value("maxLength") {
    // NOTE: 
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["maxLength"] = Keyword::new(MaxLength(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("minLength") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["minLength"] = Keyword::new(MinLength(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("pattern") {
    Some(String(s)) => schema.keywords["pattern"] = Keyword::new(Pattern(s))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("format") {
    Some(String(s)) => schema.keywords["format"] = Keyword::new(Format(s))
    None => ()
    _ => raise InvalidSchema
  }
  schema
}
