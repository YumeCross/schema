// TODO: Add refined validation support
// That is, validate function signal will be `(Self, Json) -> ValidationStatus`
// instead of simple bool values.

pub fn validate(self : ValueConstraint, value : Json) -> Bool {
  let mut valid = true
  match self.const {
    Some(const) => if value != const { return false; }
    None => ()
  }
  match self.enum_ {
    Some(arr) => arr.each(fn(val) { if value == val { valid = true } })
    None => ()
  }
  valid
}

pub fn validate(self : ArrayConstraint, value : Array[Json]) -> Bool {
  let mut valid = true
  valid = self.minItems <= value.length()
  match self.maxItems { 
    Some(max) => if max <= value.length() { return false; }
    None => ()
  }
  // TODO: uniqueItems support
  match self.items {
    Some(items) =>
      match items {
        Schema(schema) =>
          value.each(
            fn(val) { if schema.validate(val).not() { valid = false } },
          )
        SchemaArray(arr) =>
          arr.eachi(
            fn(i, schema) {
              if schema.validate(value[i]).not() {
                valid = false
              }
            },
          )
      }
    None => ()
  }
  valid
}

pub fn validate(self : NumberConstraint, value : Double) -> Bool {
  match self.maximum {
    Some(max) => if not(value <= max) { return false }
    None => ()
  }

  match self.minimum {
    Some(min) => if not(value >= min) { return false }
    None => ()
  }

  match self.exclusiveMaximum { 
    Some(e_max) => if not(value < e_max) { return false }
    None => ()
  }
  match self.exclusiveMinimum {
    Some(e_min) => if not(value > e_min) { return false }
    None => ()
  }
  true
}

pub fn validate(self : StringConstraint, value : String) -> Bool {
  let mut valid = true
  valid = self.minLength < value.length()
  self.maxLength.map(fn(maxLen) { valid = value.length() < maxLen }) |> ignore
  if valid.not() {
    return false
  }
  match self.format {
    // TODO: Check format after regex is support
    Some(_format) => ()
    None => ()
  }
  match self.pattern {
    // TODO: Check pattern after regex is support
    Some(_pattern) => ()
    None => ()
  }
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
  match self.additionalProperties {
    Bool(true) => ()
    // TODO: Check whether it limits properties from $ref.
    Bool(false) => if keys.length() > propKeys.length() { valid = false }
    // TODO: Complete
    Schema(_schema) => ()
  }
  if (self.required
    .map_option(fn(key) { if keys.contains(key) { Some(key) } else { None } })
    .length() ==
    self.required.length()).not() {
    return false
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
