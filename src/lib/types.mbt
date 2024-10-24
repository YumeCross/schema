pub struct Schema {
  // TODO: Add multiple types support.
  type_name : String
  ref : String?
  control : SchemaControl?
  constraint : ValueConstraint?
  typed_constraint : TypedSchemaConstraint
  content : Map[String, Json]
} derive(Show)

// TODO: Add support
pub struct SchemaControl {
  if_ : Schema
  then : Schema?
  else_ : Schema?
} derive(Show)

pub fn SchemaControl::new() -> SchemaControl {
  { if_: Schema::new("null"), then: None, else_: None }
}

pub struct ValueConstraint {
  const : Json?
  enum_ : Array[Json]?
} derive(Show)

pub fn ValueConstraint::new() -> ValueConstraint {
  { const: None, enum_: None }
}

pub enum TypedSchemaConstraint {
  BoolTy
  NullTy
  ArrayTy(ArrayConstraint)
  NumberTy(NumberConstraint)
  ObjectTy(ObjectConstraint)
  StringTy(StringConstraint)
} derive(Show)

enum SchemaOrSchemaArray {
  Schema(Schema)
  SchemaArray(Array[Schema])
} derive(Show)

struct ArrayConstraint {
  items : SchemaOrSchemaArray?
  minItems : Int
  maxItems : Int?
  uniqueItems : Bool
} derive(Show)

pub fn ArrayConstraint::new() -> ArrayConstraint {
  { items: None, minItems: 0, maxItems: None, uniqueItems: false }
}

struct NumberConstraint {
  minimum : Double?
  exclusiveMinimum : Double?
  maximum : Double?
  exclusiveMaximum : Double?
} derive(Show)

pub fn NumberConstraint::new() -> NumberConstraint {
  {
    minimum: None,
    exclusiveMinimum: None,
    maximum: None,
    exclusiveMaximum: None,
  }
}

enum StringArrayOrSchema {
  StringArray(Array[String])
  Schema(Schema)
} derive(Show)

enum BoolOrSchema {
  Bool(Bool)
  Schema(Schema)
} derive(Show)

struct ObjectConstraint {
  properties : Properties
  definitions : Definitions?
  required : Array[String]
  additionalProperties : BoolOrSchema
  patternProperties : Properties?
  dependencies : Map[String, StringArrayOrSchema]?
  propertyNames : Schema?
  minProperties : Int
  maxProperties : Int?
} derive(Show)

pub fn ObjectConstraint::new() -> ObjectConstraint {
  {
    properties: {},
    definitions: None,
    required: [],
    additionalProperties: Bool(true),
    patternProperties: None,
    dependencies: None,
    propertyNames: None,
    minProperties: 0,
    maxProperties: None,
  }
}

struct StringConstraint {
  format : String?
  pattern : String?
  minLength : Int
  maxLength : Int?
} derive(Show)

pub fn StringConstraint::new() -> StringConstraint {
  { format: None, pattern: None, minLength: 0, maxLength: None }
}

pub type Definition Schema derive(Show)

pub type Property Schema derive(Show)

pub typealias Properties = Map[String, Property]

pub typealias Definitions = Map[String, Definition]

pub type! ParseError {
  InvalidJson(@json.ParseError)
  InvalidSchema(String)
  InvalidMemberType(String, String, String)
  InvalidItemType(String)
} derive(Eq)

fn ParseError::make_member_type_error(
  member : String,
  specified_ty : String,
  ty : String
) -> ParseError {
  InvalidMemberType(member, specified_ty, ty)
}

pub fn to_string(self : ParseError) -> String {
  // TODO: Improve error messages.
  match self {
    InvalidItemType(s) => s
    InvalidJson(e) => e.to_string()
    InvalidMemberType(member, specified_ty, ty) =>
      "Expect \{specified_ty} for member '\{member}', got \{ty}"
    InvalidSchema(s) => s
  }
}

pub impl Show for ParseError with output(self, logger) {
  logger.write_string(self.to_string())
}

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
  inspect!(type_name(Object({})), content="object")
  inspect!(type_name(String("test")), content="string")
}
