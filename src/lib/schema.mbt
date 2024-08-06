/// Creates a new `Schema` instance based on the provided `type_name`.
/// 
/// # Parameters
/// 
/// - `type_name` : A string representing the type of the schema. Valid values are "array", "boolean", "null", "number", "object", and "string".
/// 
/// # Returns
/// 
/// A `Schema` instance initialized according to the specified `type_name`.
/// 
/// # Errors
/// 
/// The function will panic if the `type_name` is not one of the valid values.
pub fn Schema::new(type_name : String) -> Schema {
  match type_name {
    "array" =>
      { type_name, type_content: ArrayTy(ArrayContent::new()), content: {  } }
    "boolean" => { type_name, type_content: BoolTy, content: {  } }
    "null" => { type_name, type_content: NullTy, content: {  } }
    "number" =>
      { type_name, type_content: NumberTy(NumberContent::new()), content: {  } }
    "object" =>
      { type_name, type_content: ObjectTy(ObjectContent::new()), content: {  } }
    "string" =>
      { type_name, type_content: StringTy(StringContent::new()), content: {  } }
    _ => panic()
  }
}

pub fn id(self : Schema) -> String {
  self.content["$id"].unwrap().as_string().unwrap()
}

pub fn comment(self : Schema) -> String {
  self.content["$comment"].unwrap().as_string().unwrap()
}

pub fn title(self : Schema) -> String {
  self.content["title"].unwrap().as_string().unwrap()
}

pub fn description(self : Schema) -> String {
  self.content["description"].unwrap().as_string().unwrap()
}
