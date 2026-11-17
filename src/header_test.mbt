///|
test "short FL3 is recognized but truncated" {
  let error = try {
    ignore(probe_header(b"$FL3"))
    None
  } catch {
    SavFailure(e) => Some(e)
  }
  assert_eq(error.unwrap().code, "Truncated")
}

///|
test "short FL2 is truncated not unsupported" {
  let error = try {
    ignore(probe_header(b"$FL2"))
    None
  } catch {
    SavFailure(e) => Some(e)
  }
  assert_eq(error.unwrap().code, "Truncated")
}
