test "parse json pointer" {
  let p = @lib.parse_abosulute_path("#/foo/bar")
  assert_eq!(p, ["#", "foo", "bar"])
  let p = @lib.parse_abosulute_path("http://example.com/test.json#/foo/bar")
  assert_eq!(p, ["http://example.com/test.json", "#", "foo", "bar"])
}

test "show json pointer" {
  let p : @lib.JsonPointer = ["#", "foo", "bar"]
  inspect!(p, content="#/foo/bar")
  let p : @lib.JsonPointer = ["http://example.com/test.json", "#", "foo", "bar"]
  inspect!(p, content="http://example.com/test.json#/foo/bar")
}
