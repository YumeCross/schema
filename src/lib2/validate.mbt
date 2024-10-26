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
  match json {
    True | False | Null => Ok(())
    Number(num) =>
      for _, def in self.keywords {
        match def.validate_number(num) {
          Ok(_) => ()
          Err(err) =>
            return Err(
              ValidateError(
                {
                  ..err,
                  stack: ["<number>", def.name],
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
                  stack: ["<string>", def.name],
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
            Err(err) => {
              return Err(
                {
                  ..err._,
                  stack: [key, "<-dependentSchemas->", ..err._.stack],
                  expected: self,
                  received: Some(Object(obj)),
                },
              )
            }
          }
        }
      } else {
        Ok(())
      }
    _ => panic()
  }
}
