///|
priv struct DataReader {
  c : Cursor
  compression : Int
  bias : Double
  mut codes : Bytes
  mut code_index : Int
  mut ended : Bool
}

///|
fn DataReader::next(self : DataReader) -> (Bytes, Int)? raise SavError {
  if self.ended {
    return None
  }
  if self.compression == 0 {
    if self.c.pos == self.c.bytes.length() {
      self.ended = true
      return None
    }
    return Some((self.c.take(8), 253))
  }
  while true {
    if self.code_index == 8 {
      if self.c.pos == self.c.bytes.length() {
        self.ended = true
        return None
      }
      self.codes = self.c.take(8)
      self.code_index = 0
    }
    let code = self.codes[self.code_index].to_int()
    self.code_index += 1
    match code {
      0 => continue
      252 => {
        for i = self.code_index; i < 8; i = i + 1 {
          if self.codes[i] != 0 {
            reject(
              "InvalidCompression",
              "Control codes after end marker",
              offset=self.c.pos,
            )
          }
        }
        if self.c.pos != self.c.bytes.length() {
          reject(
            "InvalidCompression",
            "Bytes after compressed end marker",
            offset=self.c.pos,
          )
        }
        self.ended = true
        return None
      }
      253 => return Some((self.c.take(8), code))
      254 => return Some((b"        ", code))
      255 => return Some((bits_bytes(0xffefffffffffffffUL), code))
      _ =>
        return Some(
          (
            bits_bytes((code.to_double() - self.bias).reinterpret_as_uint64()),
            code,
          ),
        )
    }
  }
  None
}

///|
fn padded_equal(a : Bytes, b : Bytes) -> Bool {
  let n = if a.length() > b.length() { a.length() } else { b.length() }
  for i = 0; i < n; i = i + 1 {
    let x = if i < a.length() { a[i] } else { b' ' }
    let y = if i < b.length() { b[i] } else { b' ' }
    if x != y {
      return false
    }
  }
  true
}

///|
fn atom_bytes(atom : Atom) -> Bytes raise SavError {
  @base64.decode(atom.logical_bytes_base64.unwrap()) catch {
    _ => {
      reject("InvalidDictionary", "Invalid base64 atom")
      b""
    }
  }
}

///|
fn user_missing(
  v : Variable,
  bits : UInt64?,
  bytes : Bytes?,
) -> Bool raise SavError {
  if v.type_ == "numeric" {
    let value = bits.unwrap().reinterpret_as_double()
    for i = 0; i < v.missing_values.length(); i = i + 1 {
      let a = v.missing_values[i]
      if v.missing_kind != "discrete" && i == 0 {
        let lo = if a.endpoint == Some("lowest") {
          -1.7976931348623157e308
        } else {
          atom_number(a)
        }
        let upper = v.missing_values[1]
        let hi = if upper.endpoint == Some("highest") {
          1.7976931348623157e308
        } else {
          atom_number(upper)
        }
        if value >= lo && value <= hi {
          return true
        }
      } else if v.missing_kind == "discrete" || i > 1 {
        if atom_number(a) == value {
          return true
        }
      }
    }
  } else {
    for a in v.missing_values {
      if padded_equal(bytes.unwrap(), atom_bytes(a)) {
        return true
      }
    }
  }
  false
}

///|
fn atom_number(a : Atom) -> Double raise SavError {
  parse_hex(a.ieee754_hex.unwrap()).reinterpret_as_double()
}

///|
fn parse_hex(s : String) -> UInt64 raise SavError {
  if s.length() != 16 {
    reject("IntegrityMismatch", "Expected 16 lowercase hex digits")
  }
  let mut n = 0UL
  for ch in s {
    let x = ch.to_int()
    let d = if x >= 48 && x <= 57 {
      x - 48
    } else if x >= 97 && x <= 102 {
      x - 87
    } else {
      -1
    }
    if d < 0 {
      reject("IntegrityMismatch", "Invalid numeric bit representation")
    }
    n = (n << 4) | d.to_uint64()
  }
  n
}

///|
pub fn Variable::value_label_for(
  self : Variable,
  cell : Cell,
) -> String? raise SavError {
  if self.type_ != cell.kind || cell.missing == "system" {
    return None
  }
  for item in self.value_labels {
    if self.type_ == "numeric" {
      if atom_number(item.value) ==
        parse_hex(cell.ieee754_hex.unwrap()).reinterpret_as_double() {
        return Some(item.label)
      }
    } else {
      let bytes = @base64.decode(cell.logical_bytes_base64.unwrap()) catch {
        _ => {
          reject("IntegrityMismatch", "Invalid string bytes")
          b""
        }
      }
      if padded_equal(atom_bytes(item.value), bytes) {
        return Some(item.label)
      }
    }
  }
  None
}

///|
fn row_cells(
  d : Dictionary,
  slots : Array[(Bytes, Int)],
) -> Array[Cell] raise SavError {
  let row = []
  for v in d.variables {
    try {
      if v.type_ == "numeric" {
        let (bytes, opcode) = slots[v.physical_start]
        if opcode == 254 {
          reject("InvalidCompression", "Space opcode in numeric variable")
        }
        let bits = if opcode == 255 {
          parse_hex(d.system_missing_hex)
        } else {
          raw_bits(bytes)
        }
        let system = hex_bits(bits) == d.system_missing_hex
        if !system && !finite(bits.reinterpret_as_double()) {
          reject(
            "UnsupportedNumeric", "Non-sentinel NaN or infinity in numeric data",
          )
        }
        let missing = if system {
          "system"
        } else if user_missing(v, Some(bits), None) {
          "user"
        } else {
          "present"
        }
        row.push({
          kind: "numeric",
          missing,
          decimal: if system {
            None
          } else {
            Some(decimal(bits))
          },
          ieee754_hex: Some(hex_bits(bits)),
          text: None,
          logical_bytes_base64: None,
        })
      } else {
        let bytes : Array[Byte] = []
        for pair in v.segments {
          let (start, width) = pair
          for j = 0; j < (width + 7) / 8; j = j + 1 {
            let (chunk, opcode) = slots[start + j]
            if opcode != 253 && opcode != 254 {
              reject("InvalidCompression", "Numeric opcode in string variable")
            }
            let n = if width - j * 8 > 8 { 8 } else { width - j * 8 }
            for k = 0; k < n && bytes.length() < v.width; k = k + 1 {
              bytes.push(chunk[k])
            }
          }
        }
        if bytes.length() != v.width {
          reject(
            "InvalidDictionary", "Logical string reconstruction width mismatch",
          )
        }
        let bytes = Bytes::from_array(bytes)
        let text = decode(bytes, d.encoding.effective, d.options)
        row.push({
          kind: "string",
          missing: if user_missing(v, None, Some(bytes)) {
            "user"
          } else {
            "present"
          },
          decimal: None,
          ieee754_hex: None,
          text: Some(text),
          logical_bytes_base64: Some(@base64.encode(bytes)),
        })
      }
    } catch {
      SavFailure(e) => raise SavFailure({ ..e, variable_index: Some(v.index) })
    }
  }
  row
}

///|
fn snapshot_dictionary(d : Dictionary) -> Dictionary {
  {
    ..d,
    variables: d.variables.map(v => {
      ..v,
      value_labels: v.value_labels.copy(),
      missing_values: v.missing_values.copy(),
      segments: v.segments.copy(),
    }),
    warnings: d.warnings.copy(),
    uninterpreted_metadata: d.uninterpreted_metadata.copy(),
  }
}

///|
pub fn scan_bytes(
  input : Bytes,
  on_dictionary : (Dictionary) -> Unit raise Error,
  on_row : (Array[Cell]) -> ScanControl raise Error,
  options? : Options = Options::default(),
) -> ScanSummary raise SavError {
  let d = inspect_bytes(input, options~)
  on_dictionary(snapshot_dictionary(d)) catch {
    _ => reject("ConsumerFailed", "Dictionary callback failed")
  }
  let reader : DataReader = {
    c: Cursor::new(input, pos=d.data_offset),
    compression: d.compression,
    bias: d.bias,
    codes: b"",
    code_index: 8,
    ended: false,
  }
  let counts = Array::makei(d.variables.length(), _ => [0, 0, 0])
  let mut actual_rows = 0
  while true {
    let first = reader.next() catch {
      SavFailure(e) => raise SavFailure({ ..e, row_index: Some(actual_rows) })
    }
    if first == None {
      break
    }
    if actual_rows >= options.limits.rows {
      reject(
        "ResourceLimit",
        "rows: actual exceeds limit \{options.limits.rows}",
      )
    }
    if d.declared_rows is Some(n) && actual_rows >= n {
      reject("CaseCountMismatch", "Data contains more rows than declared")
    }
    let slots = [first.unwrap()]
    for _i = 1; _i < d.physical_slots; _i = _i + 1 {
      match reader.next() {
        Some(slot) => slots.push(slot)
        None =>
          reject(
            "Truncated",
            "Data ended in the middle of a case",
            offset=reader.c.pos,
          )
      }
    }
    let row = row_cells(d, slots) catch {
      SavFailure(e) => raise SavFailure({ ..e, row_index: Some(actual_rows) })
    }
    for i = 0; i < row.length(); i = i + 1 {
      let j = match row[i].missing {
        "present" => 0
        "user" => 1
        _ => 2
      }
      counts[i][j] += 1
    }
    actual_rows += 1
    let control = on_row(row) catch {
      _ => {
        reject("ConsumerFailed", "Row callback failed")
        Continue
      }
    }
    if control == Stop {
      return { actual_rows, completed: false, counts }
    }
  }
  if d.declared_rows is Some(n) && n != actual_rows {
    reject(
      "CaseCountMismatch",
      "Declared rows \{n}, actual rows \{actual_rows}",
      offset=reader.c.pos,
    )
  }
  { actual_rows, completed: true, counts }
}

///|
pub fn read_bytes(
  input : Bytes,
  options? : Options = Options::default(),
) -> Dataset raise SavError {
  let dict : Ref[Dictionary?] = { val: None }
  let rows = []
  let retained : Ref[Int] = { val: 0 }
  let budget_error : Ref[SavError?] = { val: None }
  let summary = scan_bytes(
    input,
    fn(d) { dict.val = Some(d) },
    fn(row) raise {
      try {
        if rows.length() > options.limits.cells / row.length() - 1 {
          reject("ResourceLimit", "Collected cell budget exceeded")
        }
        for cell in row {
          let n = if cell.kind == "numeric" {
            8
          } else {
            cell.text.unwrap().length() * 2 +
            cell.logical_bytes_base64.unwrap().length()
          }
          if n > options.limits.retained_bytes - retained.val {
            reject("ResourceLimit", "retained_bytes budget exceeded")
          }
          retained.val += n
        }
      } catch {
        e => {
          budget_error.val = Some(e)
          raise e
        }
      }
      rows.push(row)
      Continue
    },
    options~,
  ) catch {
    e =>
      match budget_error.val {
        Some(b) => raise b
        None => raise e
      }
  }
  ignore(summary)
  { dictionary: dict.val.unwrap(), rows }
}
