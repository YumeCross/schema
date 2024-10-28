pub fn validate(self : Schema, json : Json) -> Result[Unit, ValidateError] {
  if self.typ.left() != Some("") {
    match validate_type(self.typ, json) {
      Some(typ) =>
        return Err(
          ValidateError(
            {
              stack: ["<\{typ}>"],
              expected: { name: "type", data: Type(self.typ) },
              received: Some(json),
            },
          ),
        )
      None => ()
    }
  }

  match self.validate_generic(json) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  
  match self.validate_condition(json) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }

  match json {
    True | False | Null => Ok(())
    Array(arr) =>
      for _, def in self.keywords {
        match def.validate_array(arr, parent=self) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              ValidateError(
                {
                  ..err,
                  stack: [
                    "<array>",
                    ..if err.stack.is_empty() {
                      ["<:\{def.name}>"]
                    } else {
                      err.stack
                    },
                  ],
                  expected: def,
                  received: Some(json),
                },
              ),
            )
        }
      } else {
        Ok(())
      }
    Number(num) =>
      for _, def in self.keywords {
        match def.validate_number(num) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              ValidateError(
                {
                  ..err,
                  stack: ["<number>", "<:\{def.name}>"],
                  expected: def,
                  received: Some(json),
                },
              ),
            )
        }
      } else {
        Ok(())
      }
    String(str) =>
      for _, def in self.keywords {
        match def.validate_string(str) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              ValidateError(
                {
                  ..err,
                  stack: ["<string>", "<:\{def.name}>"],
                  expected: def,
                  received: Some(json),
                },
              ),
            )
        }
      } else {
        Ok(())
      }
    Object(obj) =>
      for _, def in self.keywords {
        match def.validate_object(obj, parent=self) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              ValidateError(
                {
                  ..err,
                  stack: ["<object>", ..err.stack],
                  expected: def,
                  received: Some(json),
                },
              ),
            )
        }
      } else {
        Ok(())
      }
  }
}

fn validate_type(
  either : Either[String, Array[String]],
  json : Json
) -> String? {
  match
    (match either {
      Left("number") => json.as_number().is_empty().not()
      Left("string") => json.as_string().is_empty().not()
      Left("object") => json.as_object().is_empty().not()
      Left("array") => json.as_array().is_empty().not()
      Left("boolean") => json.as_bool().is_empty().not()
      Left("null") => json.as_null().is_empty().not()
      Left(_) => panic()
      Right(_) => false // TODO: implement type checking for mutiple types
    }) {
    true => None
    false =>
      match either {
        Left(typ) => Some(typ)
        Right(types) => Some(String::concat(types, separator=" / "))
      }
  }
}

fn validate_generic(self : Schema, json : Json) -> Result[Unit, ErrorData] {
  match self.keywords["enum"] {
    Some(def) =>
      match def.data {
        Enum(values) =>
          if values.contains(json).not() {
            return Err(
              { stack: ["<:enum>"], expected: def, received: Some(json) },
            )
          }
        _ => panic()
      }
    None => ()
  }
  match self.keywords["const"] {
    Some(def) =>
      match def.data {
        Const(value) =>
          if json != value {
            return Err(
              { stack: ["<:const>"], expected: def, received: Some(json) },
            )
          } else {
            Ok(())
          }
        _ => panic()
      }
    None => Ok(())
  }
}

fn validate_array(
  self : Keyword,
  arr : Array[Json],
  ~parent : Schema
) -> Result[Unit, ErrorData] {
  match self.data {
    MinItems(min) => quick_fail_if_not(min <= arr.length())
    MaxItems(max) => quick_fail_if_not(max >= arr.length())
    UniqueItems(unique) =>
      if unique {
        let len = arr.length()
        arr.dedup()
        if len > arr.length() {
          Err(
            // TODO: Implement position reporting
            { stack: [], expected: self, received: None },
          )
        } else {
          Ok(())
        }
      } else {
        Ok(())
      }
    PrefixItems(schemas) =>
      for i, schema in schemas {
        match arr.get(i) {
          Some(item) =>
            match schema.validate(item) {
              Ok(_) => ()
              Err(err) =>
                return Err(
                  {
                    ..err._,
                    stack: [i.to_string(), ..err.stack],
                    expected: self,
                    received: Some(item),
                  },
                )
            }
          None =>
            return Err(
              { stack: [i.to_string()], expected: self, received: None },
            )
        }
      } else {
        Ok(())
      }
    Items(schema) => {
      let start = parent.keywords["prefixItems"].map_or(
        arr.length(),
        fn(keyword) {
          match keyword.data {
            PrefixItems(schemas) => schemas.length()
            _ => panic()
          }
        },
      )
      for i, item in arr[start:] {
        match schema.validate(item) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              {
                ..err._,
                stack: [i.to_string(), ..err.stack],
                expected: self,
                received: Some(item),
              },
            )
        }
      } else {
        Ok(())
      }
    }
    Contains(schema) => {
      let min = parent.keywords["minContains"].map_or(
        None,
        fn(def) {
          match def.data {
            MinContains(min) => Some(min)
            _ => None
          }
        },
      )
      let max = parent.keywords["maxContains"].map_or(
        None,
        fn(def) {
          match def.data {
            MaxContains(max) => Some(max)
            _ => None
          }
        },
      )
      let mut match_count = 0
      for _, item in arr {
        if schema.validate(item).is_ok() {
          match_count += 1
        }
      }
      if min.is_empty() && match_count == 0 {
        return Err({ stack: ["<:contains>"], expected: self, received: None })
      } else {
        let min = min.unwrap()
        if min > match_count {
          Err(
            {
              stack: ["<:minContains=\{min}>"],
              expected: self,
              received: Some(Number(match_count.to_double())),
            },
          )
        } else if max.is_empty() && match_count <= max.unwrap() {
          Err(
            {
              stack: ["<:maxContains=\{max}>"],
              expected: self,
              received: Some(Number(match_count.to_double())),
            },
          )
        } else {
          Ok(())
        }
      }
    }
    MinContains(_) | MaxContains(_) => Ok(())
    // TODO: Implement UnevaluatedItems
    UnevaluatedItems(_schema) => ...
    _ => panic()
  }
}

fn validate_number(self : Keyword, num : Double) -> Result[Unit, ErrorData] {
  match self.data {
    Minimum(min) => quick_fail_if_not(num >= min)
    Maximum(max) => quick_fail_if_not(num <= max)
    ExclusiveMinimum(min) => quick_fail_if_not(num > min)
    ExclusiveMaximum(max) => quick_fail_if_not(num < max)
    MultipleOf(divisor) =>
      quick_fail_if_not(num.to_int() % divisor.to_int() == 0)
    _ => panic()
  }
}

fn validate_string(self : Keyword, str : String) -> Result[Unit, ErrorData] {
  match self.data {
    MinLength(min) => quick_fail_if_not(min <= str.length())
    MaxLength(max) => quick_fail_if_not(max >= str.length())
    Enum(values) => quick_fail_if_not(values.contains(String(str)))
    Const(value) => quick_fail_if(value != String(str))
    _ => panic()
  }
}

fn validate_object(
  self : Keyword,
  obj : Map[String, Json],
  ~parent : Schema
) -> Result[Unit, ErrorData] {
  match self.data {
    MinProperties(min) =>
      quick_fail_if_not(min <= obj.keys().collect().length())
    MaxProperties(max) =>
      quick_fail_if_not(max >= obj.keys().collect().length())
    Properties(props) =>
      for key, prop in props {
        match obj[key] {
          Some(value) =>
            match prop.validate(value) {
              Ok(_) => ()
              Err(err) =>
                return Err(
                  {
                    ..err._,
                    stack: [key, ..err._.stack],
                    received: Some(value),
                  },
                )
            }
          None => ()
        }
      } else {
        Ok(())
      }
    Required(keys) =>
      for _, key in keys {
        if obj.contains(key).not() {
          return Err({ stack: [key], expected: self, received: None })
        }
      } else {
        Ok(())
      }
    AdditionalProperties(either) => {
      let props = parent.keywords["properties"].map_or(
        [],
        fn(def) {
          match def.data {
            Properties(props) =>
              obj.keys().filter(fn(key) { props.contains(key).not() }).collect()
            _ => panic()
          }
        },
      )
      either.either(
        fn(additional) {
          if additional.not() && props.is_empty().not() {
            Err(
              { stack: ["<object>", props[0]], expected: self, received: None },
            )
          } else {
            Ok(())
          }
        },
        fn(additional) {
          for key, value in obj {
            if props.contains(key) {
              match additional.validate(value) {
                Ok(_) => ()
                Err(err) =>
                  return Err(
                    {
                      ..err._,
                      stack: [key, ..err._.stack],
                      expected: self,
                      received: Some(value),
                    },
                  )
              }
            }
          } else {
            Ok(())
          }
        },
      )
    }
    DependentRequired(deps) =>
      for key, dependents in deps {
        if obj.contains(key) {
          let mut dep : String? = None
          for dependent in dependents {
            if obj.contains(dependent).not() {
              dep = Some(dependent)
              break
            }
          }
          match dep {
            Some(dep) =>
              return Err(
                {
                  stack: ["<object>", key, "-<:dependentRequired>-", dep],
                  expected: self,
                  received: None,
                },
              )
            None => ()
          }
        }
      } else {
        Ok(())
      }
    DependentSchemas(deps) =>
      for key, schema in deps {
        if obj.contains(key) {
          match schema.validate(Object(obj)) {
            Ok(_) => ()
            Err(err) =>
              return Err(
                {
                  ..err._,
                  stack: [key, "-<:dependentSchemas>-", ..err._.stack],
                  expected: self,
                  received: Some(Object(obj)),
                },
              )
          }
        }
      } else {
        Ok(())
      }
    _ => panic()
  }
}

fn validate_composition(self : Schema, json : Json) -> Result[Unit, ErrorData] {
  match self.keywords["allOf"] {
    Some(def) =>
      match def.validate_composition(json) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    None => ()
  }
  match self.keywords["anyOf"] {
    Some(def) =>
      match def.validate_composition(json) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    None => ()
  }
  match self.keywords["oneOf"] {
    Some(def) =>
      match def.validate_composition(json) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    None => ()
  }
  match self.keywords["not"] {
    Some(def) =>
      match def.validate_composition(json) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    None => ()
  }
  Ok(())
}

fn validate_composition(self : Keyword, json : Json) -> Result[Unit, ErrorData] {
  match self.data {
    AllOf(schemas) =>
      for schema in schemas {
        match schema.validate(json) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              {
                ..err._,
                stack: ["<:allOf>"],
                expected: self,
                received: Some(json),
              },
            )
        }
      } else {
        Ok(())
      }
    AnyOf(schemas) => {
      for schema in schemas {
        match schema.validate(json) {
          Ok(_) => return Ok(()) // short-circuit
          Err(_) => ()
        }
      }
      return Err({ stack: ["<:anyOf>"], expected: self, received: Some(json) })
    }
    OneOf(schemas) => {
      let mut matched = false
      for schema in schemas {
        match schema.validate(json) {
          Ok(_) =>
            if matched.not() {
              matched = true
            } else {
              return Err(
                { stack: ["<:oneOf>"], expected: self, received: Some(json) },
              )
            }
          Err(_) => ()
        }
      }
      if matched.not() {
        return Err(
          { stack: ["<:oneOf>"], expected: self, received: Some(json) },
        )
      } else {
        Ok(())
      }
    }
    Not(schema) =>
      match schema.validate(json) {
        Ok(_) =>
          Err({ stack: ["<:not>"], expected: self, received: Some(json) })
        Err(_) => Ok(())
      }
    _ => panic()
  }
}

fn validate_condition(self : Schema, json : Json) -> Result[Unit, ErrorData] {
  let mut matched : Bool? = None
  match self.keywords["if"] {
    Some(def) =>
      match def.data {
        If(schema) =>
          match schema.validate(json) {
            Ok(_) => matched = Some(true)
            Err(_) => matched = Some(false)
          }
        _ => panic()
      }
    None => ()
  }
  match matched {
    Some(true) =>
      match self.keywords["then"] {
        Some(def) =>
          match def.data {
            Then(schema) =>
              match schema.validate(json) {
                Ok(_) => Ok(())
                Err(err) =>
                  return Err(
                    {
                      ..err._,
                      stack: ["<:then>", ..err._.stack],
                      expected: def,
                      received: Some(json),
                    },
                  )
              }
            _ => panic()
          }
        None => Ok(())
      }
    Some(false) =>
      match self.keywords["else"] {
        Some(def) =>
          match def.data {
            Else(schema) =>
              match schema.validate(json) {
                Ok(_) => Ok(())
                Err(err) =>
                  return Err(
                    {
                      ..err._,
                      stack: ["<:else>", ..err._.stack],
                      expected: def,
                      received: Some(json),
                    },
                  )
              }
            _ => panic()
          }
        None => Ok(())
      }
    None => Ok(())
  }
}
