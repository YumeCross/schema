test "parse_pointer" {
  let p = @lib.parse_pointer("#/foo/bar")
  assert_eq!(p, @lib.AbsolutePointer(id="", ["#", "foo", "bar"]))
  let p = @lib.parse_pointer("http://example.com/test.json#/foo/bar")
  assert_eq!(
    p,
    @lib.AbsolutePointer(id="http://example.com/test.json", ["#", "foo", "bar"]),
  )
  let p = @lib.parse_pointer("1/name")
  assert_eq!(p, @lib.RelativePointer(["1", "name"]))
}

test "to_string" {
  let p : @lib.JsonPointer = @lib.AbsolutePointer(id="", ["#", "foo", "bar"])
  inspect!(p, content="#/foo/bar")
  let p : @lib.JsonPointer = @lib.AbsolutePointer(
    id="http://example.com/test.json",
    ["#", "foo", "bar"],
  )
  inspect!(p, content="http://example.com/test.json#/foo/bar")
}

test "resolve_pointer" {
  let p = @lib.parse_pointer("http://example.com/test-1.json#/foo/bar")
  let result = @lib.parse_pointer("http://example.com/test-2.json#/baz")
  assert_eq!(
    @lib.resolve_pointer(p, @lib.parse_pointer("test-2.json#/baz")),
    result,
  )
  let p = @lib.parse_pointer("http://example.com/test-1.json#/foo/bar")
  let result = @lib.parse_pointer("http://example.com/test-1.json#/bar/baz")
  assert_eq!(@lib.resolve_pointer(p, @lib.parse_pointer("#/bar/baz")), result)
}

test "resolve_value" {
  let obj : Json = {
    "foo": { "bar": 124, "baz": { "qux": 568, "qzx": "hello" } },
  }
  assert_eq!(
    @lib.parse_pointer("#/foo").resolve_value!(obj),
    { "baz": { "qux": 568, "qzx": "hello" }, "bar": 124 },
  )
  assert_eq!(@lib.parse_pointer("#/foo/bar").resolve_value!(obj), 124)
  assert_eq!(@lib.parse_pointer("#/foo/baz/qux").resolve_value!(obj), 568)
  assert_eq!(@lib.parse_pointer("#/foo/baz/qzx").resolve_value!(obj), "hello")
}

test "unsafe_parse_relative_pointer" {
  inspect!(@lib.unsafe_parse_relative_pointer("1/name"), content="1/name")
  inspect!(@lib.unsafe_parse_relative_pointer("1/info/"), content="1/info")
  inspect!(@lib.unsafe_parse_relative_pointer("1#"), content="1#")
  inspect!(@lib.unsafe_parse_relative_pointer("0-1#"), content="0-1#")
}
