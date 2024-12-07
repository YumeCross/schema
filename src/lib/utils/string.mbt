///|
pub fn is_unsigned_integer(str : String) -> Bool {
  if str.length() == 0 {
    return false
  }
  let view = str.to_array()[:]
  match view {
    ['0', _, ..] => return false
    ['0'] => return true
    _ => ()
  }
  loop view {
    ['1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '0', .. as rest] =>
      continue rest
    [] => break true
    _ => break false
  }
}

///|
pub fn is_integer(str : String) -> Bool {
  if str.length() == 0 {
    return false
  }
  let view = if str[0] == '+' || str[0] == '-' {
    str.to_array()[1:]
  } else {
    str.to_array()[:]
  }
  match view {
    ['0', _, ..] => return false
    ['0'] => return true
    _ => ()
  }
  loop view {
    ['1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '0', .. as rest] =>
      continue rest
    [] => break true
    _ => break false
  }
}

test "is_integer" {
  assert_true!(is_integer("1"))
  assert_true!(is_integer("-12"))
  assert_true!(is_integer("0"))
  assert_true!(is_integer("+0"))
  assert_false!(is_integer(""))
  assert_false!(is_integer("1.2"))
  assert_false!(is_integer("012"))
  assert_false!(is_integer("0x12"))
}
