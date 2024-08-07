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
    control: None,
    constraint: None,
    typed_constraints: NullTy,
    content: {  },
  }
  match type_name {
    "array" => { ..medium, typed_constraints: ArrayTy(ArrayConstraint::new()) }
    "boolean" => { ..medium, typed_constraints: BoolTy }
    "null" => medium
    "number" =>
      { ..medium, typed_constraints: NumberTy(NumberConstraint::new()) }
    "object" =>
      { ..medium, typed_constraints: ObjectTy(ObjectConstraint::new()) }
    "string" =>
      { ..medium, typed_constraints: StringTy(StringConstraint::new()) }
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
