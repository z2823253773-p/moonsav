///|
priv struct RawVar {
  short : Bytes
  width : Int
  slot : Int
  offset : Int
  print : Int
  write : Int
  label : Bytes?
  missing_count : Int
  missing : Array[Bytes]
  labels : Array[(Bytes, Bytes)]
  mut slots : Int
}

///|
priv struct Extension {
  subtype : Int
  size : Int
  count : Int
  offset : Int
  bytes : Bytes
}

///|
fn positive_int(s : String) -> Int raise SavError {
  let mut n = 0
  if s.is_empty() {
    reject("InvalidDictionary", "Empty integer mapping")
  }
  for ch in s {
    let d = ch.to_int() - 48
    if d < 0 || d > 9 || n > 32767 {
      reject("InvalidDictionary", "Invalid width mapping")
    }
    n = n * 10 + d
  }
  n
}

///|
fn text_pairs(
  bytes : Bytes,
  dec : (Bytes) -> String raise SavError,
) -> Array[(String, String)] raise SavError {
  let s = dec(bytes)
  let out = []
  for item in s.split("\t") {
    let item = item.to_owned().trim(chars="\x00 ").to_owned()
    if item.is_empty() {
      continue
    }
    match item.split_once("=") {
      Some((a, b)) =>
        out.push((a.to_owned(), b.to_owned().trim(chars="\x00 ").to_owned()))
      None => reject("InvalidDictionary", "Malformed extension mapping")
    }
  }
  out
}

///|
pub fn inspect_bytes(
  input : Bytes,
  options? : Options = Options::default(),
) -> Dictionary raise SavError {
  validate_limits(options.limits)
  let l = options.limits
  limit(input.length(), l.input_bytes, "input_bytes")
  ignore(probe_header(input))
  let c = Cursor::new(input, pos=68)
  let slots = c.i32()
  let compression = c.i32()
  let weight = c.i32()
  let cases = c.i32()
  let bias = c.f64()
  if slots < -1 {
    reject("InvalidDictionary", "Case width must be positive", offset=68)
  }
  if slots > 0 {
    limit(slots, l.physical_slots, "physical_slots")
  }
  if slots > l.row_bytes / 8 {
    reject("ResourceLimit", "row_bytes exceeds limit", offset=68)
  }
  if compression != 0 && compression != 1 {
    reject(
      "UnsupportedCompression",
      "Only compression 0 and 1 are supported",
      offset=72,
    )
  }
  if cases < -1 {
    reject("InvalidDictionary", "Invalid declared row count", offset=80)
  }
  if !finite(bias) {
    reject("InvalidCompression", "Compression bias must be finite", offset=84)
  }
  let date = c.take(9)
  let time = c.take(8)
  let file_label = c.take(64)
  ignore(c.take(3))
  let raw : Array[RawVar] = []
  let by_slot : Map[Int, RawVar] = {}
  let extensions : Array[Extension] = []
  let extras : Array[Extra] = []
  let mut label_entries = 0
  let mut physical = 0
  let mut continuation = 0
  let mut machine : Int? = None
  let mut declared : String? = None
  let mut system = 0xffefffffffffffffUL
  let mut lowest = 0xffeffffffffffffeUL
  let mut highest = 0x7fefffffffffffffUL
  let mut ext_cases : Int? = None
  while true {
    limit(c.pos - 176, l.dictionary_bytes, "dictionary_bytes")
    let offset = c.pos
    let record = c.i32()
    try {
      match record {
        2 => {
          let width = c.i32()
          let has_label = c.i32()
          let missing_count = c.i32()
          let print = c.i32()
          let write = c.i32()
          let short = c.take(8)
          if has_label != 0 && has_label != 1 {
            reject("InvalidDictionary", "Invalid label flag", offset~)
          }
          if missing_count < -3 || missing_count > 3 || missing_count == -1 {
            reject(
              "InvalidDictionary",
              "Invalid missing definition count",
              offset~,
            )
          }
          let label = if has_label == 1 {
            let n = c.i32()
            if n < 0 {
              reject("InvalidLength", "Negative variable label length", offset~)
            }
            limit(n, l.label_bytes, "label_bytes")
            let b = c.take(n)
            ignore(c.take((4 - n % 4) % 4))
            Some(b)
          } else {
            None
          }
          let missing = []
          for _i = 0; _i < missing_count.abs(); _i = _i + 1 {
            missing.push(c.take(8))
          }
          if width == -1 {
            if continuation <= 0 || raw.is_empty() {
              reject("InvalidDictionary", "Unexpected continuation", offset~)
            }
            if has_label != 0 || missing_count != 0 {
              reject(
                "InvalidDictionary",
                "Continuation declares semantic fields",
                offset~,
              )
            }
            raw[raw.length() - 1].slots += 1
            continuation -= 1
          } else {
            if continuation != 0 {
              reject(
                "InvalidDictionary",
                "Missing continuation record",
                offset~,
              )
            }
            if width < 0 || width > 255 {
              reject(
                "InvalidDictionary",
                "Invalid physical variable width",
                offset~,
              )
            }
            if width > 0 && missing_count < 0 {
              reject(
                "InvalidDictionary",
                "String range missing is invalid",
                offset~,
              )
            }
            limit(raw.length() + 1, l.variables, "variables")
            raw.push({
              short,
              width,
              slot: physical,
              offset,
              print,
              write,
              label,
              missing_count,
              missing,
              labels: [],
              slots: 1,
            })
            by_slot[physical] = raw[raw.length() - 1]
            continuation = if width == 0 { 0 } else { (width + 7) / 8 - 1 }
          }
          physical += 1
          limit(physical, l.physical_slots, "physical_slots")
        }
        3 => {
          if continuation != 0 {
            reject(
              "InvalidDictionary",
              "Unfinished variable continuations",
              offset~,
            )
          }
          let n = c.i32()
          if n < 0 {
            reject("InvalidLength", "Negative label count", offset~)
          }
          limit(n, l.dictionary_bytes / 4096, "dictionary_label_entries")
          let labels = []
          for _i = 0; _i < n; _i = _i + 1 {
            let value = c.take(8)
            let len = c.take(1)[0].to_int()
            let label = c.take(len)
            ignore(c.take((8 - (len + 1) % 8) % 8))
            labels.push((value, label))
          }
          if c.i32() != 4 {
            reject(
              "InvalidDictionary",
              "Value labels require association record 4",
              offset=c.pos - 4,
            )
          }
          let nvars = c.i32()
          if nvars <= 0 || nvars > raw.length() {
            reject(
              "InvalidDictionary",
              "Invalid label association count",
              offset=c.pos - 4,
            )
          }
          if n > (l.dictionary_bytes / 4096 - label_entries) / nvars {
            reject(
              "ResourceLimit", "Dictionary label entry bookkeeping exceeds budget",
            )
          }
          label_entries += n * nvars
          let mut label_width = -1
          for _i = 0; _i < nvars; _i = _i + 1 {
            let index = c.i32() - 1
            let mut found = false
            for
              v in (match by_slot.get(index) {
                Some(v) => [v]
                None => []
              }) {
              if v.slot == index {
                if v.width > 8 ||
                  (label_width != -1 && (label_width == 0) != (v.width == 0)) {
                  reject(
                    "InvalidDictionary",
                    "Incompatible value label association",
                    offset~,
                  )
                }
                if !v.labels.is_empty() {
                  reject(
                    "InvalidDictionary",
                    "Duplicate label association",
                    offset~,
                  )
                }
                label_width = v.width
                for pair in labels {
                  v.labels.push(pair)
                }
                found = true
              }
            }
            if !found {
              reject(
                "InvalidDictionary",
                "Label association points outside a variable start",
                offset~,
              )
            }
          }
        }
        6 => {
          let n = c.i32()
          if n < 0 {
            reject("InvalidLength", "Negative document count", offset~)
          }
          if n > l.extension_bytes / 80 {
            reject("ResourceLimit", "Document record exceeds budget", offset~)
          }
          extras.push({
            record,
            subtype: None,
            byte_offset: offset,
            raw_base64: @base64.encode(c.take(n * 80)),
          })
        }
        7 => {
          let subtype = c.i32()
          let size = c.i32()
          let count = c.i32()
          if size <= 0 || count < 0 {
            reject("InvalidLength", "Invalid extension size/count", offset~)
          }
          if count > l.extension_bytes / size {
            reject("ResourceLimit", "Extension payload exceeds budget", offset~)
          }
          let bytes = c.take(size * count)
          let e = Cursor::new(bytes)
          match subtype {
            3 => {
              if size != 4 || count != 8 {
                reject(
                  "InvalidDictionary",
                  "Invalid machine integer record",
                  offset~,
                )
              }
              ignore(e.i32())
              ignore(e.i32())
              ignore(e.i32())
              ignore(e.i32())
              let float_rep = e.i32()
              ignore(e.i32())
              let endian = e.i32()
              machine = Some(e.i32())
              if float_rep != 1 {
                reject(
                  "UnsupportedFloat",
                  "Non IEEE754 representation",
                  offset~,
                )
              }
              if endian != 2 {
                reject(
                  "UnsupportedLayout",
                  "Machine declares non-little-endian layout",
                  offset~,
                )
              }
            }
            4 => {
              if size != 8 || count != 3 {
                reject(
                  "InvalidDictionary",
                  "Invalid floating information record",
                  offset~,
                )
              }
              system = e.u64()
              highest = e.u64()
              lowest = e.u64()
              if !finite(system.reinterpret_as_double()) ||
                !finite(lowest.reinterpret_as_double()) ||
                !finite(highest.reinterpret_as_double()) {
                reject("UnsupportedFloat", "Invalid floating sentinel", offset~)
              }
            }
            16 => {
              if size != 8 || count != 2 {
                reject(
                  "InvalidDictionary",
                  "Invalid extended case count record",
                  offset~,
                )
              }
              if e.u64() != 1UL {
                reject(
                  "UnsupportedExtension",
                  "Unknown extended case count version",
                  offset~,
                )
              }
              let n = e.u64()
              if n != 0xffffffffffffffffUL {
                if n > 2147483647UL {
                  reject(
                    "ResourceLimit",
                    "Declared case count exceeds index capacity",
                    offset~,
                  )
                }
                ext_cases = Some(n.to_int())
              }
            }
            20 => {
              if size != 1 || declared != None {
                reject(
                  "InvalidDictionary",
                  "Invalid duplicate encoding record",
                  offset~,
                )
              }
              declared = Some(ascii(bytes).trim(chars="\x00 ").to_owned())
            }
            11 | 13 | 14 | 21 | 22 =>
              extensions.push({ subtype, size, count, offset, bytes })
            5 | 6 | 7 | 8 | 9 | 10 | 12 | 17 | 18 | 19 | 24 =>
              extras.push({
                record,
                subtype: Some(subtype),
                byte_offset: offset,
                raw_base64: @base64.encode(bytes),
              })
            _ =>
              reject(
                "UnsupportedExtension",
                "Unknown dictionary extension subtype \{subtype}",
                offset~,
              )
          }
        }
        999 => {
          if c.i32() != 0 {
            reject(
              "InvalidDictionary",
              "Invalid dictionary terminator",
              offset~,
            )
          }
          break
        }
        _ =>
          reject(
            "InvalidDictionary",
            "Unexpected dictionary record type \{record}",
            offset~,
          )
      }
    } catch {
      SavFailure(e) => {
        let subtype = if record == 7 && input.length() - offset >= 8 {
          Some(Cursor::new(input, pos=offset + 4).i32())
        } else {
          None
        }
        raise SavFailure({
          ..e,
          record: Some(record),
          subtype,
          byte_offset: match e.byte_offset {
            Some(n) => Some(n)
            None => Some(offset)
          },
        })
      }
    }
  }
  limit(c.pos - 176, l.dictionary_bytes, "dictionary_bytes")
  if continuation != 0 {
    reject(
      "InvalidDictionary",
      "Dictionary/header physical slots disagree",
      offset=c.pos,
    )
  }
  if ext_cases is Some(n) && cases >= 0 && n != cases {
    reject("CaseCountMismatch", "Header and extended case counts disagree")
  }
  let rows = match ext_cases {
    Some(n) => Some(n)
    None => if cases < 0 { None } else { Some(cases) }
  }
  if raw.is_empty() {
    reject(
      "InvalidDictionary", "A supported dataset requires at least one variable",
    )
  }
  let encoding = encoding_info(declared, machine, options)
  let decoded_bytes : Ref[Int] = { val: 0 }
  let dec = fn(b) raise SavError {
    let text = decode(b, encoding.effective, options)
    if text.length() > (l.dictionary_bytes - decoded_bytes.val) / 2 {
      reject("ResourceLimit", "Decoded dictionary budget exceeded")
    }
    decoded_bytes.val += text.length() * 2
    text
  }
  let raw_names : Map[String, Bool] = {}
  for r in raw {
    let key = dec(r.short).trim(chars=" \x00").to_owned().to_upper()
    raw_names[key] = true
  }
  let names : Map[String, String] = {}
  let widths : Map[String, Int] = {}
  let mut display : Array[Int] = []
  for ext in extensions {
    if ext.subtype == 13 || ext.subtype == 14 {
      if ext.size != 1 {
        reject(
          "InvalidDictionary",
          "Mapping extension size must be one",
          offset=ext.offset,
        )
      }
      for pair in text_pairs(ext.bytes, dec) {
        let (key, value) = pair
        let key = key.to_upper()
        if ext.subtype == 13 {
          if names.contains(key) {
            reject(
              "InvalidDictionary",
              "Duplicate long-name mapping",
              offset=ext.offset,
            )
          }
          names[key] = value
        } else {
          if widths.contains(key) {
            reject(
              "InvalidDictionary",
              "Duplicate long-width mapping",
              offset=ext.offset,
            )
          }
          let n = positive_int(value)
          if n <= 255 {
            reject(
              "InvalidDictionary",
              "Very long width must exceed 255",
              offset=ext.offset,
            )
          }
          limit(n, l.string_bytes, "string_bytes")
          widths[key] = n
        }
      }
    }
    if ext.subtype == 11 {
      if !display.is_empty() ||
        ext.size != 4 ||
        (ext.count != raw.length() * 3 && ext.count != raw.length() * 2) {
        reject(
          "InvalidDictionary",
          "Invalid display parameters record",
          offset=ext.offset,
        )
      }
      let e = Cursor::new(ext.bytes)
      display = Array::makei(ext.count, _ => e.i32())
    }
  }
  let vars = []
  let used : Map[String, Int] = {}
  let mut i = 0
  while i < raw.length() {
    let r = raw[i]
    let short = dec(r.short).trim(chars=" \x00").to_owned()
    let key = short.to_upper()
    let name = names.get(key).unwrap_or(short)
    let width = widths.get(key).unwrap_or(r.width)
    if short.is_empty() || name.is_empty() {
      reject("InvalidDictionary", "Empty variable name", offset=r.offset)
    }
    let nsegments = if width > 255 { (width + 251) / 252 } else { 1 }
    if nsegments > raw.length() - i {
      reject(
        "InvalidDictionary",
        "Very long string segment count is truncated",
        offset=r.offset,
      )
    }
    let segments = []
    let mut physical_slots = 0
    let mut available = 0
    for j = 0; j < nsegments; j = j + 1 {
      let s = raw[i + j]
      if j > 0 &&
        (
          s.width <= 0 ||
          s.label != None ||
          s.missing_count != 0 ||
          !s.labels.is_empty() ||
          widths.contains(
            dec(s.short).trim(chars=" \x00").to_owned().to_upper(),
          )
        ) {
        reject(
          "InvalidDictionary",
          "Overlapping or semantic very-long continuation",
          offset=s.offset,
        )
      }
      segments.push((s.slot, s.width))
      physical_slots += s.slots
      available += s.width
    }
    if width > 255 && available < width {
      reject(
        "InvalidDictionary",
        "Very long string segments are too short",
        offset=r.offset,
      )
    }
    for alias in [short, name] {
      let alias = alias.to_upper()
      if used.get(alias) is Some(previous) && previous != vars.length() {
        reject("InvalidDictionary", "Ambiguous variable alias", offset=r.offset)
      }
      used[alias] = vars.length()
    }
    let missing = []
    let is_numeric = r.width == 0
    for j = 0; j < r.missing.length(); j = j + 1 {
      if is_numeric {
        let bits = raw_bits(r.missing[j])
        let endpoint = if r.missing_count < 0 && j < 2 {
          if bits == lowest {
            Some("lowest")
          } else if bits == highest {
            Some("highest")
          } else {
            Some("finite")
          }
        } else {
          None
        }
        missing.push(numeric_atom(bits, endpoint~))
      } else {
        missing.push(string_atom(r.missing[j], dec))
      }
    }
    if r.missing_count < 0 &&
      raw_bits(r.missing[0]).reinterpret_as_double() >
      raw_bits(r.missing[1]).reinterpret_as_double() {
      reject("InvalidDictionary", "Reversed missing range", offset=r.offset)
    }
    let labels : Array[ValueLabel] = []
    for pair in r.labels {
      let (value, label) = pair
      let atom = if is_numeric {
        numeric_atom(raw_bits(value))
      } else {
        string_atom(value, dec)
      }
      labels.push({
        value: atom,
        label: dec(label),
        raw_label_base64: @base64.encode(label),
      })
    }
    let stride = if display.length() == raw.length() * 3 { 3 } else { 2 }
    let has_display = !display.is_empty()
    vars.push({
      index: vars.length(),
      short_name: short,
      name,
      type_: if is_numeric {
        "numeric"
      } else {
        "string"
      },
      width,
      label: r.label.map(b => dec(b)),
      raw_label_base64: r.label.map(b => @base64.encode(b)),
      source_offset: r.offset,
      physical_start: r.slot,
      physical_slots,
      print_format: format(r.print),
      write_format: format(r.write),
      value_labels: labels,
      missing_kind: if r.missing_count < 0 {
        if r.missing_count == -3 {
          "range_plus_discrete"
        } else {
          "range"
        }
      } else {
        "discrete"
      },
      missing_values: missing,
      measure: if has_display {
        Some(display[i * stride])
      } else {
        None
      },
      display_width: if has_display && stride == 3 {
        Some(display[i * stride + 1])
      } else {
        None
      },
      alignment: if has_display {
        Some(display[i * stride + stride - 1])
      } else {
        None
      },
      segments,
    })
    i += nsegments
  }
  for key, _ in names {
    if !raw_names.contains(key) {
      reject("InvalidDictionary", "Dangling long-name mapping")
    }
  }
  for key, _ in widths {
    if !used.contains(key) {
      reject("InvalidDictionary", "Dangling long-width mapping")
    }
  }
  apply_long_semantics(vars, extensions, dec, l)
  validate_variables(
    vars,
    hex_bits(lowest),
    hex_bits(highest),
    "InvalidDictionary",
    l,
  )
  let mut nominal = 0
  for v in vars {
    nominal += if v.type_ == "numeric" {
      1
    } else {
      ((if v.width > 255 { 255 } else { v.width }) + 7) / 8
    }
  }
  if slots > 0 && slots != physical && slots != nominal {
    reject(
      "InvalidDictionary", "Nominal case width disagrees with both defined conventions",
    )
  }
  if physical > l.row_bytes / 8 {
    reject("ResourceLimit", "Actual row width exceeds byte budget")
  }
  let weight_variable = if weight == 0 {
    None
  } else {
    let mut found : Int? = None
    for v in vars {
      if v.physical_start == weight - 1 && v.type_ == "numeric" {
        found = Some(v.index)
      }
    }
    if found == None {
      reject("InvalidDictionary", "Invalid weight variable reference")
    }
    found
  }
  let warnings = []
  if encoding.selection_source == "override" {
    warnings.push({
      warning_code: "EncodingOverride",
      scope: "dictionary_and_data",
      suggested_action: "Confirm selected encoding with the data provider",
    })
  }
  if !extras.is_empty() {
    warnings.push({
      warning_code: "UninterpretedMetadata",
      scope: "dictionary",
      suggested_action: "Consult retained raw metadata for higher-level semantics",
    })
  }
  for v in vars {
    if v.print_format.code >= 20 && v.print_format.code <= 39 {
      warnings.push({
        warning_code: "RawDateFormat",
        scope: "variable:\{v.index}",
        suggested_action: "Date/time values remain numeric; consult print/write format",
      })
    }
  }
  {
    variables: vars,
    declared_rows: rows,
    compression,
    bias,
    physical_slots: physical,
    nominal_case_size: slots,
    encoding,
    file_label: dec(file_label).trim_end(chars=" \x00").to_owned(),
    creation_date: ascii(date),
    creation_time: ascii(time),
    product: dec(input[4:64].to_bytes()).trim_end(chars=" \x00").to_owned(),
    weight_variable,
    warnings,
    uninterpreted_metadata: extras,
    system_missing_hex: hex_bits(system),
    lowest_hex: hex_bits(lowest),
    highest_hex: hex_bits(highest),
    data_offset: c.pos,
    options,
  }
}

///|
fn apply_long_semantics(
  vars : Array[Variable],
  extensions : Array[Extension],
  dec : (Bytes) -> String raise SavError,
  limits : Limits,
) -> Unit raise SavError {
  let mut label_entries = 0
  for v in vars {
    label_entries += v.value_labels.length()
  }
  let by_name : Map[String, Int] = {}
  for v in vars {
    by_name[v.name.to_upper()] = v.index
    by_name[v.short_name.to_upper()] = v.index
  }
  for ext in extensions {
    if ext.subtype != 21 && ext.subtype != 22 {
      continue
    }
    if ext.size != 1 {
      reject(
        "InvalidDictionary",
        "Invalid long string semantic extension",
        offset=ext.offset,
      )
    }
    let c = Cursor::new(ext.bytes)
    while c.pos < ext.bytes.length() {
      let n = c.i32()
      limit(n, limits.label_bytes, "label_bytes")
      let name = dec(c.take(n))
      let index = by_name.get(name.to_upper()).unwrap_or(-1)
      if index < 0 || vars[index].type_ != "string" {
        reject(
          "InvalidDictionary",
          "Dangling long string semantic reference",
          offset=ext.offset,
        )
      }
      let v = vars[index]
      if ext.subtype == 21 {
        let width = c.i32()
        if width != v.width {
          reject(
            "InvalidDictionary",
            "Long label width mismatch",
            offset=ext.offset,
          )
        }
        let nlabels = c.i32()
        if nlabels < 0 {
          reject("InvalidLength", "Negative long label count")
        }
        if nlabels > limits.dictionary_bytes / 4096 - label_entries {
          reject(
            "ResourceLimit", "Dictionary label entry bookkeeping exceeds budget",
          )
        }
        label_entries += nlabels
        for _i = 0; _i < nlabels; _i = _i + 1 {
          let len = c.i32()
          if len < 0 || len > v.width {
            reject(
              "InvalidLength",
              "Invalid long label key length",
              offset=ext.offset,
            )
          }
          let value = string_atom(c.take(len), dec)
          let length = c.i32()
          limit(length, limits.label_bytes, "label_bytes")
          let label = c.take(length)
          v.value_labels.push({
            value,
            label: dec(label),
            raw_label_base64: @base64.encode(label),
          })
        }
      } else {
        let count = c.take(1)[0].to_int()
        if count < 1 || count > 3 || !v.missing_values.is_empty() {
          reject(
            "InvalidDictionary",
            "Invalid long missing count",
            offset=ext.offset,
          )
        }
        let width = c.i32()
        if width < 1 || width > v.width {
          reject(
            "InvalidLength",
            "Invalid long missing width",
            offset=ext.offset,
          )
        }
        for _i = 0; _i < count; _i = _i + 1 {
          v.missing_values.push(string_atom(c.take(width), dec))
        }
      }
    }
  }
}
