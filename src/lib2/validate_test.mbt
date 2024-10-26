test "validate string" {
  let s1 : @lib2.Schema = {
    typ: Left("string"),
    keywords: { "enum": { data: @lib2.Enum(["1", "2", "3"]), name: "enum" } },
  }
  assert_true!(s1.validate(String("1")).is_ok())
  assert_false!(s1.validate(String("test")).is_ok())
  let s2 : @lib2.Schema = {
    typ: Left("string"),
    keywords: {
      "minLength": { data: @lib2.MinLength(1), name: "minLength" },
      "maxLength": { data: @lib2.MaxLength(3), name: "maxLength" },
    },
  }
  assert_true!(s2.validate(String("123")).is_ok())
  assert_false!(s2.validate(String("1234")).is_ok())
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
                  data: Properties({ "test": { typ: Left("string"), keywords: {} } },),
                },
              },
            },
          ),
        ),
      },
    },
  }
  println(
    s1.validate(
      { "name": String("John"), "age": 30, "address": { "test": "eee" } }.to_json(),
    ),
  )
}
