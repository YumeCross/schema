fn assert_ok![T, E : Show](
  result : Result[T, E],
  ~loc : SourceLoc = _
) -> Unit! {
  match result {
    Ok(_) => ()
    Err(e) => fail!(e.to_string(), ~loc)
  }
}

fn assert_err![T : Show, E : Show](
  result : Result[T, E],
  ~loc : SourceLoc = _
) -> Unit! {
  match result {
    Err(_) => ()
    Ok(_) => fail!("`result` is not an error", ~loc)
  }
}

test "validate enum/const" {
  let s1 : @lib2.Schema = {
    typ: Left("string"),
    keywords: { "enum": { data: @lib2.Enum(["1", "2", "3"]), name: "enum" } },
  }
  assert_true!(s1.validate(String("1")).is_ok())
  assert_false!(s1.validate(String("test")).is_ok())
  let s2 : @lib2.Schema = {
    typ: Left("string"),
    keywords: { "const": { data: @lib2.Const("test"), name: "const" } },
  }
  assert_true!(s2.validate(String("test")).is_ok())
  assert_false!(s2.validate(String("1")).is_ok())
}

test "validate array" {
  let s1 : @lib2.Schema = {
    typ: Left("array"),
    keywords: {
      "items": {
        name: "items",
        data: Items(
          {
            typ: Left("string"),
            keywords: {
              "enum": { data: @lib2.Enum(["1", "2", "3", "4"]), name: "enum" },
            },
          },
        ),
      },
      "prefixItems": {
        name: "prefixItems",
        data: PrefixItems(
          [
            { typ: Left("number"), keywords: {} },
            { typ: Left("number"), keywords: {} },
          ],
        ),
      },
    },
  }
  assert_true!(s1.validate([2, 4]).is_ok())
  assert_true!(s1.validate([1, 2, "4"]).is_ok())
  assert_false!(s1.validate(["1", "2", "3"]).is_ok())
  assert_false!(s1.validate([1, 2, 3, "4"]).is_ok())
  let s2 : @lib2.Schema = {
    typ: Left("array"),
    keywords: {
      "items": {
        name: "items",
        data: Items({ typ: Left("string"), keywords: {} }),
      },
      "minItems": { data: @lib2.MinItems(2), name: "minItems" },
      "maxItems": { data: @lib2.MaxItems(5), name: "maxItems" },
    },
  }
  assert_true!(s2.validate(["1", "2"]).is_ok())
  assert_false!(s2.validate([]).is_ok())
  assert_false!(s2.validate(["1", "3", "5", "7", "9", "11"]).is_ok())
}

test "validate array contains" {
  let s1 : @lib2.Schema = {
    typ: Left("array"),
    keywords: {
      "contains": {
        name: "contains",
        data: Contains({ typ: Left("number"), keywords: {} }),
      },
      "minContains": { name: "minContains", data: MinContains(2) },
      "maxContains": { name: "maxContains", data: MaxContains(3) },
    },
  }
  assert_true!(s1.validate([1, 2, 3]).is_ok())
  assert_true!(s1.validate([1, 2, "3"]).is_ok())
  assert_false!(s1.validate([1, "2"]).is_ok())
}

test "validate number" {
  let s : @lib2.Schema = {
    typ: @utils.Left("number"),
    keywords: @lib2.of([@lib2.ExclusiveMaximum(12), @lib2.Minimum(1)]),
  }
  assert_ok!(s.validate(11))
  assert_err!(s.validate(0))
  assert_err!(s.validate(12))
}

test "validate string" {
  let s1 : @lib2.Schema = {
    typ: Left("string"),
    keywords: {
      "minLength": { data: @lib2.MinLength(1), name: "minLength" },
      "maxLength": { data: @lib2.MaxLength(3), name: "maxLength" },
    },
  }
  assert_true!(s1.validate(String("123")).is_ok())
  assert_false!(s1.validate(String("1234")).is_ok())
}

test "validate object" {
  let s1 : @lib2.Schema = {
    typ: Left("object"),
    keywords: {
      "properties": {
        name: "properties",
        data: Properties({ "test": { typ: Left("string"), keywords: {} } }),
      },
      "additionalProperties": {
        name: "additionalProperties",
        data: AdditionalProperties(Right({ typ: Left("number"), keywords: {} })),
      },
    },
  }
  assert_true!(s1.validate({ "test": "Hello World" }.to_json()).is_ok())
  assert_true!(s1.validate({ "a": 12345 }.to_json()).is_ok())
  assert_false!(s1.validate({ "test": 1.0 }.to_json()).is_ok())
}

test "validate object additionalProperties" {
  let s1 : @lib2.Schema = {
    typ: Left("object"),
    keywords: {
      "required": { name: "required", data: Required(["name", "age"]) },
      "properties": {
        name: "properties",
        data: Properties(
          {
            "name": { typ: Left("string"), keywords: {} },
            "age": { typ: Left("number"), keywords: {} },
          },
        ),
      },
      "additionalProperties": {
        name: "additionalProperties",
        data: AdditionalProperties(
          Right(
            {
              typ: Left("object"),
              keywords: {
                "properties": {
                  name: "properties",
                  data: Properties(
                    { "test": { typ: Left("string"), keywords: {} } },
                  ),
                },
              },
            },
          ),
        ),
      },
    },
  }
  assert_true!(
    s1
    .validate(
      { "name": String("John"), "age": 30, "address": { "test": "eee" } }.to_json(),
    )
    .is_ok(),
  )
}

test "validate object dependencies" {
  let s1 : @lib2.Schema = {
    typ: Left("object"),
    keywords: {
      "properties": {
        name: "properties",
        data: Properties(
          {
            "name": { typ: Left("string"), keywords: {} },
            "age": { typ: Left("number"), keywords: {} },
            "identity": { typ: Left("string"), keywords: {} },
          },
        ),
      },
      "dependentRequired": {
        name: "dependentRequired",
        data: DependentRequired({ "name": ["identity"] }),
      },
    },
  }
  assert_true!(s1.validate({ "age": 30 }.to_json()).is_ok())
  assert_true!(
    s1
    .validate({ "name": String("John"), "age": 30, "identity": "123" })
    .is_ok(),
  )
  assert_false!(
    s1.validate({ "name": String("John"), "age": 30 }.to_json()).is_ok(),
  )
  let s2 : @lib2.Schema = {
    typ: Left("object"),
    keywords: {
      "properties": {
        name: "properties",
        data: Properties(
          {
            "name": { typ: Left("string"), keywords: {} },
            "age": { typ: Left("number"), keywords: {} },
          },
        ),
      },
      "dependentSchemas": {
        name: "dependentSchemas",
        data: DependentSchemas(
          {
            "name": {
              typ: Left("object"),
              keywords: {
                "properties": {
                  name: "properties",
                  data: Properties(
                    { "identity": { typ: Left("string"), keywords: {} } },
                  ),
                },
              },
            },
          },
        ),
      },
    },
  }
  assert_true!(
    s2.validate({ "name": String("John"), "age": 30 }.to_json()).is_ok(),
  )
  assert_true!(
    s2
    .validate(
      { "name": String("John"), "age": 30, "identity": "00123" }.to_json(),
    )
    .is_ok(),
  )
  assert_false!(
    s2.validate({ "name": false, "age": 30, "identity": "12300" }).is_ok(),
  )
}

test "validate composition" {
  let s1 : @lib2.Schema = {
    typ: Left(""),
    keywords: {
      "anyOf": {
        name: "anyOf",
        data: AnyOf(
          [
            { typ: Left("boolean"), keywords: {} },
            {
              typ: Left("number"),
              keywords: {
                "minimum": { data: @lib2.Minimum(10), name: "minimum" },
              },
            },
          ],
        ),
      },
    },
  }
  assert_ok!(s1.validate(true))
  assert_ok!(s1.validate(15))
  assert_err!(s1.validate(5))
  let s2 : @lib2.Schema = {
    typ: Left(""),
    keywords: {
      "allOf": {
        name: "allOf",
        data: AllOf(
          [
            {
              typ: Left("object"),
              keywords: {
                "properties": {
                  name: "properties",
                  data: Properties(
                    {
                      "name": { typ: Left("string"), keywords: {} },
                      "age": { typ: Left("number"), keywords: {} },
                    },
                  ),
                },
              },
            },
            {
              typ: Left(""),
              keywords: {
                "properties": {
                  name: "properties",
                  data: Properties(
                    { "id": { typ: Left("string"), keywords: {} } },
                  ),
                },
                "required": { name: "required", data: Required(["id"]) },
              },
            },
          ],
        ),
      },
    },
  }
  assert_ok!(s2.validate({ "name": String("John"), "age": 30, "id": "123" }))
  assert_err!(s2.validate({ "name": String("John"), "age": 30 }))
}

test "validate condition" {

}
