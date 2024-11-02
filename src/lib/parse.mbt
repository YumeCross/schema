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
  // Parse array-specific keywords
  match json.value("items") {
    Some(Object(_) as v) =>
      schema.keywords["items"] = Keyword::new(Items(parse!(v)))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("prefixItems") {
    Some(Array(arr)) => {
      let prefix = []
      for v in arr {
        prefix.push(parse!(v))
      }
      schema.keywords["prefixItems"] = Keyword::new(PrefixItems(prefix))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("contains") {
    Some(Object(_) as v) =>
      schema.keywords["contains"] = Keyword::new(Contains(parse!(v)))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("maxItems") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["maxItems"] = Keyword::new(MaxItems(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("minItems") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["minItems"] = Keyword::new(MinItems(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("minContains") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["minContains"] = Keyword::new(MinContains(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("maxContains") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["maxContains"] = Keyword::new(MaxContains(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("uniqueItems") {
    Some(True) =>
      schema.keywords["uniqueItems"] = Keyword::new(UniqueItems(true))
    Some(False) =>
      schema.keywords["uniqueItems"] = Keyword::new(UniqueItems(false))
    None => ()
    _ => raise InvalidSchema
  }
  // Parse object-specific keywords
  match json.value("properties") {
    Some(Object(obj)) => {
      let props = {}
      for k, v in obj {
        props[k] = parse!(v)
      }
      schema.keywords["properties"] = Keyword::new(Properties(props))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("required") {
    Some(Array(arr)) => {
      let required = []
      for v in arr {
        match v.as_string() {
          Some(s) => required.push(s)
          None => raise InvalidSchema
        }
      }
      schema.keywords["required"] = Keyword::new(Required(required))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("dependentRequired") {
    Some(Object(obj)) => {
      let dependent = {}
      for k, v in obj {
        match v.as_array() {
          Some(arr) => {
            let arr2 = arr.map_option(fn(v) { v.as_string() })
            if arr.length() != arr2.length() {
              raise InvalidSchema
            }
            dependent[k] = arr2
          }
          None => raise InvalidSchema
        }
      }
      schema.keywords["dependentRequired"] = Keyword::new(
        DependentRequired(dependent),
      )
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("dependentSchemas") {
    Some(Object(obj)) => {
      let dependent = {}
      for k, v in obj {
        dependent[k] = parse!(v)
      }
      schema.keywords["dependentSchemas"] = Keyword::new(
        DependentSchemas(dependent),
      )
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("additionalProperties") {
    Some(True) =>
      schema.keywords["additionalProperties"] = Keyword::new(
        AdditionalProperties(Left(true)),
      )
    Some(False) =>
      schema.keywords["additionalProperties"] = Keyword::new(
        AdditionalProperties(Left(false)),
      )
    Some(Object(_) as v) =>
      schema.keywords["additionalProperties"] = Keyword::new(
        AdditionalProperties(Right(parse!(v))),
      )
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("minProperties") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["minProperties"] = Keyword::new(MinProperties(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("maxProperties") {
    Some(Number(n)) => {
      assert_integer!(n)
      schema.keywords["maxProperties"] = Keyword::new(MaxProperties(n.to_int()))
    }
    None => ()
    _ => raise InvalidSchema
  }
  // Parse composition keywords
  match json.value("allOf") {
    Some(Array(arr)) => {
      let all_of = []
      for v in arr {
        all_of.push(parse!(v))
      }
      schema.keywords["allOf"] = Keyword::new(AllOf(all_of))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("anyOf") {
    Some(Array(arr)) => {
      let any_of = []
      for v in arr {
        any_of.push(parse!(v))
      }
      schema.keywords["anyOf"] = Keyword::new(AnyOf(any_of))
    }
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("oneOf") {
    Some(Array(arr)) => {
      let one_of = []
      for v in arr {
        one_of.push(parse!(v))
      }
      schema.keywords["oneOf"] = Keyword::new(OneOf(one_of))
    }
    None => ()
    _ => raise InvalidSchema
  }
  // Parse conditional keywords
  match json.value("not") {
    Some(Object(_) as v) =>
      schema.keywords["not"] = Keyword::new(Not(parse!(v)))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("if") {
    Some(Object(_) as v) => schema.keywords["if"] = Keyword::new(If(parse!(v)))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("then") {
    Some(Object(_) as v) =>
      schema.keywords["then"] = Keyword::new(Then(parse!(v)))
    None => ()
    _ => raise InvalidSchema
  }
  match json.value("else") {
    Some(Object(_) as v) =>
      schema.keywords["else"] = Keyword::new(Else(parse!(v)))
    None => ()
    _ => raise InvalidSchema
  }
  // TODO: Parse structure keywords
  schema
}
