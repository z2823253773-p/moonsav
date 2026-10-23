///|
test "reject FL3 by actual magic not extension" {
  let error = try {
    ignore(probe_header(b"$FL3"))
    None
  } catch {
    SavFailure(e) => Some(e)
  }
  assert_eq(error.unwrap().code, "UnsupportedCompression")
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
