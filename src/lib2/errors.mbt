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

fn quick_fail_if_not(success : Bool) -> Result[Unit, ErrorData] {
  quick_fail_if(success.not())
}
