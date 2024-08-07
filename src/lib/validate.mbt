/// Returns the type name of a Json value as a String.
/// 
/// Possible return values are "array", "boolean", "null", "number", "object", and "string".
fn type_name(value: @json.JsonValue) -> String {
  match value {
    Array(_) => "array"
    True | False => "boolean"
    Null => "null"
    Number(_) => "number"
    Object(_) => "objecr"
    String(_) => "string"
  }
}

test "type_name" {
    inspect!(type_name(Array([])), content="array")
    inspect!(type_name(True), content="boolean")
    inspect!(type_name(Null), content="null")
    inspect!(type_name(Number(42.0)), content="number")
    inspect!(type_name(Object({})), content="object")
    inspect!(type_name(String("test")), content="string")
}

pub fn validate(self: Schema, value: @json.JsonValue) -> Bool {
  if self.type_name != type_name(value) { return false }
  // TODO: Complete
  true
}
