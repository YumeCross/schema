pub struct Schema {
  type_name : String
  control : SchemaControl?
  constraint : SchemaConstraint?
  typed_constraints : TypedSchemaConstraint
  content : Map[String, @json.JsonValue]
}

pub struct SchemaControl {
  if_ : Schema
  then : Schema?
  else_ : Schema?
}

pub fn SchemaControl::new() -> SchemaControl {
  { if_: Schema::new("null"), then: None, else_: None }
}

pub struct SchemaConstraint {
  const : (@json.JsonValue?, Schema?)
  enum_ : Array[(@json.JsonValue?, Schema?)]?
}

pub fn SchemaConstraint::new() -> SchemaConstraint {
  { const: (None, None), enum_: None }
}

pub enum TypedSchemaConstraint {
  BoolTy
  NullTy
  ArrayTy(ArrayConstraint)
  NumberTy(NumberConstraint)
  ObjectTy(ObjectConstraint)
  StringTy(StringConstraint)
}

struct ArrayConstraint {
  items : (Schema?, Array[Schema]?)
  minItems : UInt
  maxItems : UInt?
  uniqueItems : Bool
}

pub fn ArrayConstraint::new() -> ArrayConstraint {
  { items: (None, None), minItems: 0, maxItems: None, uniqueItems: false }
}

struct NumberConstraint {
  minimum : Double?
  exclusiveMinimum : Double?
  maximum : Double?
  exclusiveMaximum : Double?
}

pub fn NumberConstraint::new() -> NumberConstraint {
  {
    minimum: None,
    exclusiveMinimum: None,
    maximum: None,
    exclusiveMaximum: None,
  }
}

struct ObjectConstraint {
  properties : Properties
  definitions : Definitions?
  required : Array[String]
  additionalProperties : (Bool, Schema?)
  patternProperties : Schema?
  dependencies : (Map[String, Array[String]], Schema?)
  propertyNames : Schema?
  minProperties : UInt
  maxProperties : UInt?
}

pub fn ObjectConstraint::new() -> ObjectConstraint {
  {
    properties: {  },
    definitions: None,
    required: [],
    additionalProperties: (true, None),
    patternProperties: None,
    dependencies: ({  }, None),
    propertyNames: None,
    minProperties: 0,
    maxProperties: None,
  }
}

struct StringConstraint {
  format : String?
  pattern : String?
  minLength : UInt
  maxLength : UInt?
}

pub fn StringConstraint::new() -> StringConstraint {
  { format: None, pattern: None, minLength: 0, maxLength: None }
}

pub type Definition Schema

pub type Property Schema

pub typealias Properties = Map[String, Property]

pub typealias Definitions = Map[String, Definition]

enum ErrorData {
  InvalidJson(@json.ParseError)
  InvalidSchema(String)
  InvalidType(String)
} derive(Eq)

pub type! ParseError ErrorData
