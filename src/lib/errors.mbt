///|
fn quick_fail_if(failed : Bool) -> Result[Unit, ErrorData] {
  if failed {
    Err(
      {
        stack: [],
        expected: { name: "", data: Const(Null) },
        received: Some(Null),
      },
    )
  } else {
    Ok(())
  }
}

///|
fn quick_fail_if_not(success : Bool) -> Result[Unit, ErrorData] {
  quick_fail_if(success.not())
}

///|
fn assert_ok![T, E : Show](
  result : Result[T, E],
  loc~ : SourceLoc = _
) -> Unit! {
  match result {
    Ok(_) => ()
    Err(e) => fail!(e.to_string(), loc~)
  }
}

///|
fn assert_err![T : Show, E : Show](
  result : Result[T, E],
  loc~ : SourceLoc = _
) -> Unit! {
  match result {
    Err(_) => ()
    Ok(_) => fail!("`result` is not an error", loc~)
  }
}
