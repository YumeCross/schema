/// Checks if a specified member in a object has a specific type.
/// 
/// # Parameters
/// 
/// - `member` : The name of the member.
/// - `specified_ty` : The expected type name of the member.
/// - `map` : The data of the Json object.
/// 
/// # Returns
/// 
/// - Optional value if the member matches the type or doesn't exist.
/// 
/// # Errors
/// 
/// - `ParseError` : If the member exists but does not match the specified type, a `ParseError` is returned with details about the mismatch.
fn check1(
  member : String,
  specified_ty : String,
  map : Map[String, Json]
) -> Json?!ParseError {
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

fn checkn(
  member : String,
  specified_tys : Array[String],
  map : Map[String, Json]
) -> Json?!ParseError {
  let option = map[member]
  if option.is_empty() {
    return None
  }
  let mut result : Result[Unit, ParseError] = Ok(())
  let value = option.map(
    fn(value) {
      let ty_name = type_name(value)
      let mut invalid = true
      specified_tys.each(fn(ty) { if ty == ty_name { invalid = false } })
      let msg = specified_tys
        ..mapi_inplace(
          fn(i, s) {
            if i == specified_tys.length() - 2 {
              s + " or " + specified_tys[i + 1]
            } else if i == specified_tys.length() - 1 {
              ""
            } else {
              s + ", "
            }
          },
        )
        .join("")
      if invalid {
        result = Err(
          ParseError::make_member_type_error(
            member,
            " a value of \{msg}",
            ty_name,
          ),
        )
      }
      value
    },
  )
  result.unwrap_or_error!()
  value
}

fn parse_schema_value_constraint(
  medium : Schema,
  object : Map[String, Json]
) -> Schema!ParseError {
  let mut ty_name = medium.type_name
  if ty_name == "null" {
    if object["const"].is_empty().not() {
      ty_name = type_name(object["const"].unwrap())
    }
    if object["enum_"].is_empty().not() {
      // TODO: Modify the type of Schema::type_name to Array[String]
    }
  }
  let constraint = {
    const: check1!("const", medium.type_name, object),
    enum_: check1!("enum", "array", object).map(
      fn(val) { val.as_array().unwrap() },
    ),
  }
  { ..medium, constraint: Some(constraint) }
}

fn parse_array_schema(
  medium : Schema,
  object : Map[String, Json]
) -> Schema!ParseError {
  let constraint = {
    items: match checkn!("items", ["array", "object"], object) {
      Some(v) => {
        match v {
          Array(arr) => {
            let mut maybe_e: Result[Unit, ParseError] = Ok(())
            let v = Some(
              SchemaArray(
                arr.map_option(fn(obj) {
                  parse?(obj).map_err(fn(e) { maybe_e = Err(e) }).to_option()
                })
              )
            )
            maybe_e.unwrap_or_error!()
            v
          }
          Object(obj) => {
            Some(SchemaOrSchemaArray::Schema(parse!(Object(obj))))
          }
          _ => panic()
        }
      }
      None => None
    },
    minItems: check1!("minItems", "number", object).map_or(
      0,
      fn(v) { v.as_number().unwrap().to_int() },
    ),
    maxItems: check1!("minItems", "number", object).map(
      fn(v) { v.as_number().unwrap().to_int() },
    ),
    uniqueItems: check1!("uniqueItems", "boolean", object).map_or(
      false,
      fn(v) { v.as_bool().unwrap() },
    ),
  }
  { ..medium, typed_constraint: ArrayTy(constraint) }
}

fn parse_number_schema(
  medium : Schema,
  object : Map[String, Json]
) -> Schema!ParseError {
  let constraint = {
    minimum: check1!("minimum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
    maximum: check1!("maximum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
    exclusiveMinimum: check1!("exclusiveMinimum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
    exclusiveMaximum: check1!("exclusiveMaximum", "number", object).map(
      fn(v) { v.as_number().unwrap() },
    ),
  }
  { ..medium, typed_constraint: NumberTy(constraint) }
}

fn parse_object_schema(
  medium : Schema,
  map : Map[String, Json]
) -> Schema!ParseError {
  let mut result : Result[Unit, ParseError] = Ok(())
  let constraint = {
    minProperties: check1!("minProperties", "number", map).map_or(
      0,
      fn(val) { val.as_number().unwrap().to_int() },
    ),
    maxProperties: check1!("maxProperties", "number", map).map(
      fn(val) { val.as_number().unwrap().to_int() },
    ),
    required: check1!("required", "array", map).map_or(
      [],
      fn(val) {
        val
        .as_array()
        .unwrap()
        .map_option(
          fn(item) {
            item
            .as_string()
            .map_or_else(
              fn() {
                let ty_name = type_name(item)
                result = Err(
                  ParseError(
                    InvalidItemType(
                      "Expect a item of type string in 'required', got \{ty_name}",
                    ),
                  ),
                )
                None
              },
              fn(val) { Some(val) },
            )
          },
        )
      },
    ),
    properties: check1!("properties", "object", map).map_or(
      {  },
      fn(val) {
        let obj = val.as_object().unwrap()
        let keys = obj.keys().collect()
        let props : Map[String, Property] = {  }
        for i = 0; i < keys.length(); i = i + 1 {
          let key = keys[i]
          match parse?(obj[key].unwrap()) {
            Ok(schema) => props[key] = schema
            Err(e) => {
              result = Err(e)
              break
            }
          }
        }
        props
      },
    ),
    // TODO
    definitions: None,
    additionalProperties: checkn!(
      "additionalProperties",
      ["boolean", "object"],
      map,
    ).map_or(
      Bool(true),
      fn(val) {
        match val {
          True | False as v => Bool(v.as_bool().unwrap())
          Object(_) =>
            parse?(val)
            .map_err(fn(e) { result = Err(e) })
            .map(fn(v) { BoolOrSchema::Schema(v) })
            .or(Bool(true))
          _ => Bool(true)
        }
      },
    ),
    patternProperties: check1!("patternProperties", "object", map).map(
      fn(val) {
        let obj = val.as_object().unwrap()
        let keys = obj.keys().collect()
        let props : Map[String, Property] = {  }
        for i = 0; i < keys.length(); i = i + 1 {
          let key = keys[i]
          match parse?(obj[key].unwrap()) {
            Ok(schema) => props[key] = schema
            Err(e) => {
              result = Err(e)
              break
            }
          }
        }
        props
      },
    ),
    propertyNames: check1!("propertyNames", "object", map).map_or(
      None,
      fn(val) {
        let obj = val.as_object().unwrap()
        if obj.get_or_init("type", fn() { "string" }) != "string" {
          result = Err(
            ParseError(
              InvalidSchema("Invalid 'type' string in 'propertyNames'"),
            ),
          )
        }
        parse?(val).map_err(fn(e) { result = Err(e) }).to_option()
      },
    ),
    dependencies: check1!("dependencies", "object", map).map(
      fn(val) {
        let obj = val.as_object().unwrap()
        let deps : Map[String, StringArrayOrSchema] = {  }
        let keys = obj.keys().collect()
        for i = 0; i < keys.length(); i = i + 1 {
          let key = keys[i]
          let maybe_e = checkn?(key, ["object", "array"], obj).map_err(
            fn(e) { result = Err(e) },
          )
          if result.is_err() {
            return {  }
          }
          maybe_e
          .to_option()
          .map(
            fn(val) {
              match val.unwrap() {
                Array(arr) =>
                  deps[key] = StringArray(
                    arr.map_option(
                      fn(item) {
                        if result.is_err() {
                          return None
                        }
                        match item.as_string() {
                          Some(s) => Some(s)
                          None => {
                            let ty_name = type_name(item)
                            result = Err(
                              ParseError(
                                InvalidItemType(
                                  "Expect a item of type string in 'required', got \{ty_name}",
                                ),
                              ),
                            )
                            None
                          }
                        }
                      },
                    ),
                  )
                Object(obj) =>
                  parse?(Object(obj))
                  .map_err(fn(e) { result = Err(e) })
                  .map(fn(sch) { deps[key] = Schema(sch) })
                  |> ignore
                _ => panic()
              }
            },
          )
          |> ignore
        }
        deps
      },
    ),
  }
  result.unwrap_or_error!()
  { ..medium, typed_constraint: ObjectTy(constraint) }
}

fn parse_string_schema(
  medium : Schema,
  object : Map[String, Json]
) -> Schema!ParseError {
  let constraint = {
    format: check1!("format", "string", object).map(
      fn(v) { v.as_string().unwrap() },
    ),
    pattern: check1!("pattern", "string", object).map(
      fn(v) { v.as_string().unwrap() },
    ),
    minLength: check1!("minLength", "number", object).map_or(
      0,
      fn(v) { v.as_number().unwrap().to_int() },
    ),
    maxLength: check1!("maxLength", "number", object).map(
      fn(v) { v.as_number().unwrap().to_int() },
    ),
  }
  { ..medium, typed_constraint: StringTy(constraint) }
}

/// Parses a Json object to create dchema.
/// 
/// # Parameters
/// 
/// - `object` : A Json object representing the schema to be parsed.
/// 
/// # Returns
/// 
/// A `Schema` instance if the parsing is successful.
/// 
/// # Errors
/// 
/// - `ParseError` : If the Json value is not an valid schema. 
pub fn parse(object : Json) -> Schema!ParseError {
  // TODO: Complete
  match object.as_object() {
    Some(_) => ()
    None => {
      let ty_name = type_name(object)
      raise ParseError(InvalidSchema("Expect a Json object, got \{ty_name}"))
    }
  }
  let map = object.as_object().unwrap()
  let mut schema = Schema::new("null")
  // TODO: Some schema may not need type (through attribute like "const" to infer)
  match map {
    { "type": "array" } =>
      schema = parse_array_schema!(Schema::new("array"), map)
    { "type": "number" } =>
      schema = parse_number_schema!(Schema::new("number"), map)
    { "type": "string" } =>
      schema = parse_string_schema!(Schema::new("string"), map)
    { "type": "object" } =>
      schema = parse_object_schema!(Schema::new("object"), map)
    { "type"?: None, "const": const } =>
      {
        map["type"] = String(type_name(const))
        return parse!(Object(map))
      }
    _ =>
      raise ParseError(
        InvalidSchema(
          "Invalid member 'type', should be one of 'array', 'boolean', 'null', 'number', 'object', 'string'",
        ),
      )
  }
  schema = parse_schema_value_constraint!(schema, map)
  schema = { ..schema, content: map }
  schema
}
