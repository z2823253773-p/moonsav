///|
fn contract_manifest() -> Json {
  let hash = "0000000000000000000000000000000000000000000000000000000000000000"
  {
    "schema_version": "moonsav.bundle/1",
    "profile": "ndjson",
    "actual_rows": 0,
    "logical_variables": 1,
    "input": { "size_bytes": 293, "sha256": hash },
    "files": {
      "metadata.json": { "size_bytes": 0, "sha256": hash },
      "codebook.md": { "size_bytes": 0, "sha256": hash },
      "data.ndjson": { "size_bytes": 0, "sha256": hash },
    },
  }
}

///|
fn contract_dictionary_json(nominal : Int) -> String raise SavError {
  let d = inspect_bytes(
    b"\x24\x46\x4c\x32\x40\x28\x23\x29\x20\x4d\x6f\x6f\x6e\x53\x61\x76\x20\x69\x6e\x64\x65\x70\x65\x6e\x64\x65\x6e\x74\x20\x66\x69\x78\x74\x75\x72\x65\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x02\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x59\x40\x30\x31\x20\x4a\x41\x4e\x20\x32\x36\x30\x30\x3a\x30\x30\x3a\x30\x30\x53\x79\x6e\x74\x68\x65\x74\x69\x63\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x05\x00\x00\x08\x05\x00\x53\x43\x4f\x52\x45\x20\x20\x20\x07\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\xe9\xfd\x00\x00\x07\x00\x00\x00\x14\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x55\x54\x46\x2d\x38\xe7\x03\x00\x00\x00\x00\x00\x00\xfc\x00\x00\x00\x00\x00\x00\x00",
  )
  let j = metadata_json(d, 0)
  match j {
    Object(o) => o["nominal_case_size"] = nominal.to_json()
    _ => abort("object")
  }
  j.stringify()
}

///|
test "nominal unknown widths are preserved and checked by direct constructor" {
  for nominal in [-1, 0, 1] {
    let c = BundleChecker::new(
      contract_dictionary_json(nominal),
      contract_manifest(),
    )
    assert_eq(c.dictionary.nominal_case_size, nominal)
    assert_eq(c.finish().actual_rows, 0)
  }
}

///|
test "direct checker constructor validates limits even without check_manifest" {
  let options = {
    ..Options::default(),
    limits: { ..Limits::default(), rows: 1000001 },
  }
  let code = try {
    ignore(
      BundleChecker::new(
        contract_dictionary_json(1),
        contract_manifest(),
        options~,
      ),
    )
    "accepted"
  } catch {
    e => e.info().code
  }
  assert_eq(code, "ResourceLimit")
}

///|
test "raw decoded and associated-label budget boundaries are independent" {
  let b = DictionaryBudget::new({ ..Limits::default(), dictionary_bytes: 8 })
  b.raw(8)
  b.decoded("abcd")
  let raw = try {
    b.raw(1)
    "accepted"
  } catch {
    e => e.info().code
  }
  let decoded = try {
    b.decoded("x")
    "accepted"
  } catch {
    e => e.info().code
  }
  assert_eq(raw, "ResourceLimit")
  assert_eq(decoded, "ResourceLimit")
  let entries = DictionaryBudget::new({
    ..Limits::default(),
    dictionary_bytes: 16384,
  })
  entries.labels(2, associations=2)
  let extra = try {
    entries.labels(1)
    "accepted"
  } catch {
    e => e.info().code
  }
  assert_eq(extra, "ResourceLimit")
  let overflow = try {
    entries.labels(2147483647, associations=2147483647)
    "accepted"
  } catch {
    e => e.info().code
  }
  assert_eq(overflow, "ResourceLimit")
}

///|
test "canonical decimal preserves signed zero subnormals and necessary exponents" {
  jdecimal("1", 0x3ff0000000000000UL)
  jdecimal("-0", 0x8000000000000000UL)
  jdecimal("5e-324", 1UL)
  jdecimal("1e+30", 0x46293e5939a08ceaUL)
  jdecimal("1.7976931348623157e+308", 0x7fefffffffffffffUL)
  for text in ["01", "+1", "1.0", "1e0"] {
    let code = try {
      jdecimal(text, 0x3ff0000000000000UL)
      "accepted"
    } catch {
      e => e.info().code
    }
    assert_eq(code, "IntegrityMismatch")
  }
}

///|
test "custom decoder identities cannot be empty or contain NUL" {
  for id in ["", "   ", "bad\x00identity"] {
    let code = try {
      ignore(
        encoding_info(Some("UTF-8"), None, {
          ..Options::default(),
          decoder_identity: Some(id),
          decoder: Some(fn(_, _) { "" }),
        }),
      )
      "accepted"
    } catch {
      e => e.info().code
    }
    assert_eq(code, "UnsupportedEncodingVariant")
  }
}

///|
test "dictionary callback edits cannot mutate active parser state" {
  let summary = scan_bytes(
    b"\x24\x46\x4c\x32\x40\x28\x23\x29\x20\x4d\x6f\x6f\x6e\x53\x61\x76\x20\x69\x6e\x64\x65\x70\x65\x6e\x64\x65\x6e\x74\x20\x66\x69\x78\x74\x75\x72\x65\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x02\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x59\x40\x30\x31\x20\x4a\x41\x4e\x20\x32\x36\x30\x30\x3a\x30\x30\x3a\x30\x30\x53\x79\x6e\x74\x68\x65\x74\x69\x63\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x05\x00\x00\x08\x05\x00\x53\x43\x4f\x52\x45\x20\x20\x20\x07\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\x08\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\x01\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\xe9\xfd\x00\x00\x07\x00\x00\x00\x14\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x55\x54\x46\x2d\x38\xe7\x03\x00\x00\x00\x00\x00\x00\xfc\x00\x00\x00\x00\x00\x00\x00",
    fn(d) { d.variables.clear() },
    fn(_) { Continue },
  )
  assert_eq(summary.completed, true)
  assert_eq(summary.counts.length(), 1)
}

///|
test "checker summaries do not expose mutable internal count storage" {
  let c = BundleChecker::new(contract_dictionary_json(1), contract_manifest())
  let first = c.finish()
  first.counts[0][0] = 9
  assert_eq(c.finish().counts[0][0], 0)
}
