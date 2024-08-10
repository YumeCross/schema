/// # Parameters
/// 
/// - `value` : A Json value.
/// 
/// # Returns
/// 
/// The type name of a Json value as a String.
/// Possible return values are "array", "boolean", "null", "number", "object", and "string".
fn type_name(value : Json) -> String {
  match value {
    Array(_) => "array"
    True | False => "boolean"
    Null => "null"
    Number(_) => "number"
    Object(_) => "object"
    String(_) => "string"
  }
}

test "type_name" {
  inspect!(type_name(Array([])), content="array")
  inspect!(type_name(True), content="boolean")
  inspect!(type_name(Null), content="null")
  inspect!(type_name(Number(42.0)), content="number")
  inspect!(type_name(Object({  })), content="object")
  inspect!(type_name(String("test")), content="string")
}

pub fn validate(self : ValueConstraint, value : Json) -> Bool {
  let mut valid = true
  self.const.map(fn(const) { valid = value == const }) |> ignore
  self.enum_.map(
    fn(arr) {
      valid = false
      arr.each(fn(val) { if value == val { valid = true } })
    },
  )
  |> ignore
  valid
}

pub fn validate(self : ArrayConstraint, value : Array[Json]) -> Bool {
  let mut valid = true
  valid = self.minItems <= value.length()
  self.maxItems.map(fn(max) { valid = max >= value.length() }) |> ignore
  // TODO
  match self.items {
    Some(items) => {
      match items {
        Schema(schema) => {
          value.each(fn(val) { if schema.validate(val).not() { valid = false } })
        }
        SchemaArray(arr) => {
          arr.eachi(fn(i, schema) {
            if schema.validate(value[i]).not() { valid = false }
          })
        }
      }
    }
    None => ()
  }
  valid
}

pub fn validate(self : NumberConstraint, value : Double) -> Bool {
  let mut valid = true
  self.maximum.map(fn(max) { if not(value <= max) { valid = false } }) |> ignore
  self.minimum.map(fn(min) { if not(value >= min) { valid = false } }) |> ignore
  self.exclusiveMaximum.map(
    fn(e_max) { if not(value < e_max) { valid = false } },
  )
  |> ignore
  self.exclusiveMinimum.map(
    fn(e_min) { if not(value > e_min) { valid = false } },
  )
  |> ignore
  valid
}

pub fn validate(self : StringConstraint, value : String) -> Bool {
  let mut valid = true
  valid = self.minLength < value.length()
  self.maxLength.map(fn(maxLen) { valid = value.length() < maxLen }) |> ignore
  if valid.not() {
    return false
  }
  self.format.map(
    fn(format) {
      // TODO: Check format after regex is support
      valid = true
    },
  )
  |> ignore
  self.pattern.map(
    fn(pattern) {
      // TODO: Check pattern after regex is support
      valid = true
    },
  )
  |> ignore
  valid
}

pub fn validate(self : ObjectConstraint, value : Map[String, Json]) -> Bool {
  let mut valid = true
  let keys = value.keys().collect()
  let propKeys = self.properties.keys().collect()
  // TODO: Check reference
  valid = self.minProperties <= keys.length()
  self.maxProperties.map(fn(max) { valid = max >= keys.length() }) |> ignore
  if valid.not() {
    return false
  }
  let mut key = propKeys[0]
  for i = 0; i < propKeys.length(); i = i + 1 {
    key = propKeys[i]
    let val = value[key].map_or_else(
      fn() {
        valid = false
        None
      },
      fn(val) { Some(val) },
    )
    if valid.not() {
      return false
    }
    valid = self.properties[key].unwrap().0.validate(val.unwrap())
  }
  // TODO: Complete
  match self.additionalProperties {
    Bool(true) => ()
    Bool(false) => if keys.length() > propKeys.length() { valid = false }
    Schema(schema) => ()
  }
  if (self.required
  .map_option(fn(key) { if keys.contains(key) { Some(key) } else { None } })
  .length() == self.required.length()).not() {
    valid = false
  }
  valid
}

/// Validates whether a given Json value conforms to the schema definition.
/// 
/// # Parameters
/// 
/// - `self` : The schema.
/// - `value` : The value to be validated.
/// 
/// # Returns
/// 
/// - `Bool` : `true` if the Json value conforms to the schema, otherwise `false`.
pub fn validate(self : Schema, value : Json) -> Bool {
  if self.type_name != type_name(value) {
    return false
  }
  // TODO: Complete
  let mut valid = self.constraint.map_or(
    true,
    fn(constraint) { constraint.validate(value) },
  )
  match self.typed_constraint {
    NullTy => ()
    BoolTy => ()
    ArrayTy(constraint) =>
      if constraint.validate(value.as_array().unwrap()).not() {
        valid = false
      }
    NumberTy(constraint) =>
      if constraint.validate(value.as_number().unwrap()).not() {
        valid = false
      }
    ObjectTy(constraint) =>
      if constraint.validate(value.as_object().unwrap()).not() {
        valid = false
      }
    StringTy(constraint) =>
      if constraint.validate(value.as_string().unwrap()).not() {
        valid = false
      }
  }
  valid
}
