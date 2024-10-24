/// Creates new schema.
/// 
/// # Parameters
/// 
/// - `type_name` : A string representing the type of the schema. Valid values are "array", "boolean", "null", "number", "object", and "string".
/// 
/// @alert unsafe "Panic if invalid `type_name` is recevied."
pub fn Schema::new(type_name : String) -> Schema {
  let medium = {
    type_name,
    ref: None,
    control: None,
    constraint: None,
    typed_constraint: NullTy,
    content: {},
  }
  match type_name {
    "array" => { ..medium, typed_constraint: ArrayTy(ArrayConstraint::new()) }
    "boolean" => { ..medium, typed_constraint: BoolTy }
    "null" => medium
    "number" =>
      { ..medium, typed_constraint: NumberTy(NumberConstraint::new()) }
    "object" =>
      { ..medium, typed_constraint: ObjectTy(ObjectConstraint::new()) }
    "string" =>
      { ..medium, typed_constraint: StringTy(StringConstraint::new()) }
    _ => panic()
  }
}

/// Return the '$id' property from the schema Json.
/// 
/// @alert unsafe "Panic if not exist"
pub fn id(self : Schema) -> String {
  self.content["$id"].unwrap().as_string().unwrap()
}

/// Return the '$comment' property from the schema Json.
///
/// @alert unsafe "Panic if not exist"
pub fn comment(self : Schema) -> String {
  self.content["$comment"].unwrap().as_string().unwrap()
}

/// Return the 'title' property from the schema Json.
/// 
/// @alert unsafe "Panic if not exist"
pub fn title(self : Schema) -> String {
  self.content["title"].unwrap().as_string().unwrap()
}

/// Return the 'description' property from the schema Json.
///
/// @alert unsafe "Panic if not exist"
pub fn description(self : Schema) -> String {
  self.content["description"].unwrap().as_string().unwrap()
}
