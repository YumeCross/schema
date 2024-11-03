test "parse_path" {
  let p = @lib.parse_path("#/foo/bar")
  assert_eq!(p, @lib.AbsolutePath(id="", ["#", "foo", "bar"]))
  let p = @lib.parse_path("http://example.com/test.json#/foo/bar")
  assert_eq!(p, @lib.AbsolutePath(id="http://example.com/test.json", ["#", "foo", "bar"]))
  let p = @lib.parse_path("1/name")
  assert_eq!(p, @lib.RelativePath(["1", "name"]))
}

test "to_string" {
  let p : @lib.JsonPointer = @lib.AbsolutePath(id="", ["#", "foo", "bar"])
  inspect!(p, content="#/foo/bar")
  let p : @lib.JsonPointer = @lib.AbsolutePath(id="http://example.com/test.json", ["#", "foo", "bar"])
  inspect!(p, content="http://example.com/test.json#/foo/bar")
}

test "resolve_path" {
  let p = @lib.parse_path("http://example.com/test-1.json#/foo/bar")
  let result = @lib.parse_path("http://example.com/test-2.json#/baz")
  assert_eq!(@lib.resolve_path(p, @lib.parse_path("test-2.json#/baz")), result)

  let p = @lib.parse_path("http://example.com/test-1.json#/foo/bar")
  let result = @lib.parse_path("http://example.com/test-1.json#/bar/baz")
  assert_eq!(@lib.resolve_path(p, @lib.parse_path("#/bar/baz")), result)
}
