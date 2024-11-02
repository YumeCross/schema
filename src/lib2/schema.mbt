pub fn Keyword::new(data : KeywordData) -> Keyword {
  match data {
    //
    Schema(_) => { name: "$schema", data }
    Id(_) => { name: "$id", data }
    Ref(_) => { name: "$ref", data }
    Defs(_) => { name: "$defs", data }
    Anchor(_) => { name: "$anchor", data }
    //
    Default(_) => { name: "default", data }
    Enum(_) => { name: "enum", data }
    Const(_) => { name: "const", data }
    Type(_) => { name: "type", data }
    //
    AllOf(_) => { name: "allOf", data }
    AnyOf(_) => { name: "anyOf", data }
    OneOf(_) => { name: "oneOf", data }
    //
    Not(_) => { name: "not", data }
    If(_) => { name: "if", data }
    Then(_) => { name: "then", data }
    Else(_) => { name: "else", data }
    //
    Required(_) => { name: "required", data }
    MinProperties(_) => { name: "minProperties", data }
    MaxProperties(_) => { name: "maxProperties", data }
    DependentRequired(_) => { name: "dependentRequired", data }
    DependentSchemas(_) => { name: "dependentSchemas", data }
    Properties(_) => { name: "properties", data }
    AdditionalProperties(_) => { name: "additionalProperties", data }
    //
    MinLength(_) => { name: "minLength", data }
    MaxLength(_) => { name: "maxLength", data }
    Pattern(_) => { name: "pattern", data }
    Format(_) => { name: "format", data }
    //
    Items(_) => { name: "items", data }
    AdditionalItems(_) => { name: "additionalItems", data }
    UniqueItems(_) => { name: "uniqueItems", data }
    Contains(_) => { name: "contains", data }
    MinItems(_) => { name: "minItems", data }
    MaxItems(_) => { name: "maxItems", data }
    MinContains(_) => { name: "minContains", data }
    MaxContains(_) => { name: "maxContains", data }
    PrefixItems(_) => { name: "prefixItems", data }
    UnevaluatedItems(_) => { name: "unevaluatedItems", data }
    //
    Minimum(_) => { name: "minimum", data }
    ExclusiveMinimum(_) => { name: "exclusiveMinimum", data }
    Maximum(_) => { name: "maximum", data }
    ExclusiveMaximum(_) => { name: "exclusiveMaximum", data }
    MultipleOf(_) => { name: "multipleOf", data }
  }
}
