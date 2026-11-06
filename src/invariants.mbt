///|
fn semantic_key(a : Atom) -> String raise SavError {
  if a.type_ == "numeric" {
    let bits = parse_hex(a.ieee754_hex.unwrap())
    if bits.reinterpret_as_double() == 0.0 {
      "n:0"
    } else {
      "n:" + hex_bits(bits)
    }
  } else {
    let bytes = atom_bytes(a)
    let mut n = bytes.length()
    while n > 0 && bytes[n - 1] == b' ' {
      n -= 1
    }
    "s:" + @base64.encode(bytes[0:n])
  }
}

///|
fn validate_variables(
  vars : Array[Variable],
  lowest : String,
  highest : String,
  code : String,
  limits : Limits,
) -> Unit raise SavError {
  if vars.is_empty() {
    reject(code, "A supported dataset requires at least one logical variable")
  }
  let mut slots = 0
  for v in vars {
    validate_variable_name(v.name, code)
    validate_variable_name(v.short_name, code)
    if v.print_format.raw < 0 ||
      v.print_format.raw > 0xffffff ||
      v.write_format.raw < 0 ||
      v.write_format.raw > 0xffffff {
      reject(code, "Invalid raw print/write format", variable=v.index)
    }
    if v.measure is Some(m) && (m < 0 || m > 3) {
      reject(code, "Invalid measurement level", variable=v.index)
    }
    if v.display_width is Some(w) && w < 0 {
      reject(code, "Invalid display width", variable=v.index)
    }
    if v.alignment is Some(a) && (a < 0 || a > 2) {
      reject(code, "Invalid alignment", variable=v.index)
    }

    limit(v.width, limits.string_bytes, "string_bytes")
    let expected = if v.type_ == "numeric" {
      1
    } else if v.width <= 255 {
      (v.width + 7) / 8
    } else {
      let segments = (v.width + 251) / 252
      (segments - 1) * 32 + (v.width - (segments - 1) * 252 + 7) / 8
    }
    if v.physical_slots != expected || v.physical_start != slots {
      reject(code, "Physical layout disagrees with logical storage width")
    }
    slots += expected
    if slots > limits.row_bytes / 8 {
      reject("ResourceLimit", "Row width exceeds byte budget")
    }
    let keys : Map[String, Bool] = {}
    for item in v.value_labels {
      if item.value.endpoint != None {
        reject(code, "Value labels cannot be missing-range endpoints")
      }
      validate_string_key(item.value, v.width, false, code)
      let key = semantic_key(item.value)
      if keys.contains(key) {
        reject(
          code, "Duplicate or conflicting semantically equal value-label keys",
        )
      }
      keys[key] = true
    }
    if v.missing_kind == "discrete" {
      if v.missing_values.length() > 3 {
        reject(code, "Too many discrete missing definitions")
      }
    } else if v.type_ != "numeric" ||
      !((v.missing_kind == "range" && v.missing_values.length() == 2) ||
      (
        v.missing_kind == "range_plus_discrete" &&
        v.missing_values.length() == 3
      )) {
      reject(code, "Invalid missing definition shape")
    }
    for i = 0; i < v.missing_values.length(); i = i + 1 {
      let a = v.missing_values[i]
      validate_string_key(a, v.width, true, code)
      if v.type_ == "numeric" {
        if v.missing_kind != "discrete" && i < 2 {
          let endpoint = if i == 0 && a.ieee754_hex == Some(lowest) {
            "lowest"
          } else if i == 1 && a.ieee754_hex == Some(highest) {
            "highest"
          } else {
            "finite"
          }
          if a.endpoint != Some(endpoint) {
            reject(
              code, "Missing endpoint tag disagrees with position and file sentinel",
            )
          }
        } else if a.endpoint != None {
          reject(code, "Discrete missing value cannot carry an endpoint tag")
        }
      }
    }
  }
}

///|
fn validate_variable_name(name : String, code : String) -> Unit raise SavError {
  if name.is_empty() || name.contains("\x00") {
    reject(code, "Variable names must be nonempty and cannot contain NUL")
  }
}

///|
fn validate_case_width(
  nominal : Int,
  vars : Array[Variable],
  physical : Int,
  code : String,
) -> Unit raise SavError {
  let mut limited = 0
  for v in vars {
    limited += if v.type_ == "numeric" {
      1
    } else {
      ((if v.width > 255 { 255 } else { v.width }) + 7) / 8
    }
  }
  if nominal < -1 || (nominal > 0 && nominal != physical && nominal != limited) {
    reject(code, "Nominal case width disagrees with both defined conventions")
  }
}

///|
fn validate_string_key(
  a : Atom,
  width : Int,
  missing : Bool,
  code : String,
) -> Unit raise SavError {
  if a.type_ != "string" {
    return
  }
  let bytes = atom_bytes(a)
  if missing && bytes.length() != 8 {
    reject(code, "String missing keys require the fixed 8-byte representation")
  }
  if bytes.length() > width {
    for i = width; i < bytes.length(); i = i + 1 {
      if bytes[i] != b' ' {
        reject(code, "String key exceeds logical variable width")
      }
    }
  }
}
