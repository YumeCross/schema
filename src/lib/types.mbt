pub struct Schema {
  type_name : String
  type_content : SchemaContent
  content : Map[String, @json.JsonValue]
}

pub enum SchemaContent {
  BoolTy
  NullTy
  ArrayTy(ArrayContent)
  NumberTy(NumberContent)
  ObjectTy(ObjectContent)
  StringTy(StringContent)
}

struct ArrayContent {
  items : (Schema?, Array[Schema]?)
  minItems : UInt
  maxItems : UInt?
  uniqueItems : Bool
}

pub fn ArrayContent::new() -> ArrayContent {
  { items: (None, None), minItems: 0, maxItems: None, uniqueItems: false }
}

struct NumberContent {
  minimum : Double?
  exclusiveMinimum : Double?
  maximum : Double?
  exclusiveMaximum : Double?
}

pub fn NumberContent::new() -> NumberContent {
  {
    minimum: None,
    exclusiveMinimum: None,
    maximum: None,
    exclusiveMaximum: None,
  }
}

struct ObjectContent {
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

pub fn ObjectContent::new() -> ObjectContent {
  {
    properties: {},
    definitions: None,
    required: [],
    additionalProperties: (true, None),
    patternProperties: None,
    dependencies: ({}, None),
    propertyNames: None,
    minProperties: 0,
    maxProperties: None,
  }
}

struct StringContent {
  format : String?
  pattern : String?
  minLength : UInt
  maxLength : UInt?
}

pub fn StringContent::new() -> StringContent {
  { format: None, pattern: None, minLength: 0, maxLength: None }
}

pub type Definition Schema

pub type Property Schema

pub typealias Properties = Map[String, Property]

pub typealias Definitions = Map[String, Definition]
