/// Returns the type name of a Json value as a String.
/// 
/// Possible return values are "array", "boolean", "null", "number", "object", and "string".
fn type_name(value : @json.JsonValue) -> String {
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

pub fn validate(self : ValueConstraint, value : @json.JsonValue) -> Bool {
  let mut valid = true
  self.const.map(fn(const) { valid = value == const }) |> ignore
  self.enum_.map(fn(arr) { arr.each(fn(val) { valid = value == val }) })
  |> ignore
  valid
}

pub fn validate(self : NumberConstraint, value : Double) -> Bool {
  let mut valid = true
  self.maximum.map(fn(max) { valid = value <= max }) |> ignore
  self.minimum.map(fn(min) { valid = value >= min }) |> ignore
  self.exclusiveMaximum.map(fn(e_max) { valid = value < e_max }) |> ignore
  self.exclusiveMinimum.map(fn(e_min) { valid = value > e_min }) |> ignore
  valid
}

pub fn validate(self : StringConstraint, value : String) -> Bool {
  let mut valid = true
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
  valid = self.minLength < value.length()
  self.maxLength.map(fn(maxLen) { valid = value.length() < maxLen }) |> ignore
  valid
}

pub fn validate(self : Schema, value : @json.JsonValue) -> Bool {
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
    NumberTy(constraint) =>
      if constraint.validate(value.as_number().unwrap()).not() {
        valid = false
      }
    StringTy(constraint) =>
      if constraint.validate(value.as_string().unwrap()).not() {
        valid = false
      }
  }
  valid
}
