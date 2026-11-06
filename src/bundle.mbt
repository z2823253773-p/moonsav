///|
fn parse_json(text : String) -> Json raise SavError {
  @json.parse(text, max_nesting_depth=64) catch {
    _ => {
      reject("IntegrityMismatch", "Invalid JSON structure")
      Json::null()
    }
  }
}

///|
fn member(j : Json, key : String) -> Json raise SavError {
  match j.value(key) {
    Some(v) => v
    None => {
      reject("IntegrityMismatch", "Missing required field: " + key)
      Json::null()
    }
  }
}

///|
fn closed(j : Json, allowed : Array[String]) -> Json raise SavError {
  match j {
    Object(fields) =>
      for key, _ in fields {
        if !allowed.contains(key) {
          reject(
            "IntegrityMismatch",
            "Undocumented field in closed object: " + key,
          )
        }
      }
    _ => reject("IntegrityMismatch", "Expected JSON object")
  }
  j
}

///|
fn jstr(j : Json) -> String raise SavError {
  match j.as_string() {
    Some(s) => s
    None => {
      reject("IntegrityMismatch", "Expected string")
      ""
    }
  }
}

///|
fn jnum(j : Json) -> Int raise SavError {
  match j.as_number() {
    Some(n) => {
      if !finite(n) || n < 0 || n > 2147483647.0 || n.to_int().to_double() != n {
        reject("IntegrityMismatch", "Expected bounded nonnegative integer")
      }
      n.to_int()
    }
    None => {
      reject("IntegrityMismatch", "Expected integer")
      0
    }
  }
}

///|
fn jsigned(j : Json, minimum? : Double = -2147483648.0) -> Int raise SavError {
  match j.as_number() {
    Some(n) => {
      if !finite(n) ||
        n < minimum ||
        n > 2147483647.0 ||
        n.to_int().to_double() != n {
        reject("IntegrityMismatch", "Expected bounded signed integer")
      }
      n.to_int()
    }
    None => {
      reject("IntegrityMismatch", "Expected integer")
      0
    }
  }
}

///|
fn jarr(j : Json) -> Array[Json] raise SavError {
  match j.as_array() {
    Some(a) => a
    None => {
      reject("IntegrityMismatch", "Expected array")
      []
    }
  }
}

///|
fn opt_str(j : Json) -> String? raise SavError {
  if j == Json::null() {
    None
  } else {
    Some(jstr(j))
  }
}

///|
fn opt_int(j : Json) -> Int? raise SavError {
  if j == Json::null() {
    None
  } else {
    Some(jnum(j))
  }
}

///|
fn b64(s : String) -> Bytes raise SavError {
  let bytes = @base64.decode(s) catch {
    _ => {
      reject("IntegrityMismatch", "Invalid base64 encoding")
      b""
    }
  }
  if @base64.encode(bytes) != s {
    reject("IntegrityMismatch", "Noncanonical base64 encoding")
  }
  bytes
}

///|
fn jdecimal(s : String, bits : UInt64) -> Unit raise SavError {
  if s.length() > 64 {
    reject("IntegrityMismatch", "Numeric decimal token exceeds canonical size")
  }
  let n = @string.parse_double(s) catch {
    _ => {
      reject("IntegrityMismatch", "Invalid decimal representation")
      0.0
    }
  }
  if !finite(n) || n.reinterpret_as_uint64() != bits {
    reject("IntegrityMismatch", "Numeric decimal and IEEE754 bits disagree")
  }
  if s != decimal(bits) {
    reject(
      "IntegrityMismatch", "Numeric decimal is not the canonical shortest representation",
    )
  }
}

///|
fn dictionary_b64(
  s : String,
  budget : DictionaryBudget,
  label? : Bool = false,
  extension? : Bool = false,
) -> Bytes raise SavError {
  if s.length() % 4 != 0 {
    reject("IntegrityMismatch", "Invalid canonical base64 length")
  }
  let n = s.length() / 4 * 3 -
    (if s.has_suffix("==") { 2 } else if s.has_suffix("=") { 1 } else { 0 })
  if label {
    limit(n, budget.limits.label_bytes, "label_bytes")
  }
  if extension {
    limit(n, budget.limits.extension_bytes, "extension_bytes")
  }
  budget.raw(n)
  b64(s)
}

///|
fn parsed_atom(
  j : Json,
  kind : String,
  dec : (Bytes) -> String raise SavError,
  budget : DictionaryBudget,
) -> Atom raise SavError {
  ignore(
    closed(j, [
      "type", "decimal", "ieee754_hex", "text", "logical_bytes_base64", "width",
      "endpoint",
    ]),
  )
  if jstr(member(j, "type")) != kind {
    reject("IntegrityMismatch", "Atom type disagrees with variable")
  }
  let atom : Atom = {
    type_: kind,
    decimal: opt_str(member(j, "decimal")),
    ieee754_hex: opt_str(member(j, "ieee754_hex")),
    text: opt_str(member(j, "text")),
    logical_bytes_base64: opt_str(member(j, "logical_bytes_base64")),
    width: jnum(member(j, "width")),
    endpoint: opt_str(member(j, "endpoint")),
  }
  if kind == "numeric" {
    budget.raw(8)
    if atom.width != 8 ||
      atom.text != None ||
      atom.logical_bytes_base64 != None ||
      atom.decimal == None ||
      atom.ieee754_hex == None {
      reject("IntegrityMismatch", "Invalid numeric atom fields")
    }
    jdecimal(atom.decimal.unwrap(), parse_hex(atom.ieee754_hex.unwrap()))
  } else {
    if atom.decimal != None ||
      atom.ieee754_hex != None ||
      atom.endpoint != None ||
      atom.text == None ||
      atom.logical_bytes_base64 == None {
      reject("IntegrityMismatch", "Invalid string atom fields")
    }
    let bytes = dictionary_b64(atom.logical_bytes_base64.unwrap(), budget)
    if bytes.length() != atom.width || dec(bytes) != atom.text.unwrap() {
      reject("IntegrityMismatch", "String atom bytes/text/width disagree")
    }
  }
  atom
}

///|
fn parsed_format(j : Json) -> Format raise SavError {
  ignore(closed(j, ["raw", "code", "width", "decimals"]))
  let raw = jnum(member(j, "raw"))
  let f = format(raw)
  if f.code != jnum(member(j, "code")) ||
    f.width != jnum(member(j, "width")) ||
    f.decimals != jnum(member(j, "decimals")) {
    reject("IntegrityMismatch", "Format fields disagree with raw code")
  }
  f
}

///|
pub fn check_manifest(
  text : String,
  options? : Options = Options::default(),
) -> Json raise SavError {
  validate_limits(options.limits)
  let j = parse_json(text)
  if jstr(member(j, "schema_version")) != "moonsav.bundle/1" {
    reject("UnsupportedSchema", "Unsupported manifest schema")
  }
  let profile = jstr(member(j, "profile"))
  if profile != "csv_with_canonical" && profile != "ndjson" {
    reject("UnsupportedSchema", "Unsupported bundle profile")
  }
  let rows = jnum(member(j, "actual_rows"))
  limit(rows, options.limits.rows, "rows")
  let cols = jnum(member(j, "logical_variables"))
  if cols == 0 {
    reject("IntegrityMismatch", "Bundle has no variables")
  }
  limit(cols, options.limits.variables, "variables")
  let input = closed(member(j, "input"), ["size_bytes", "sha256"])
  limit(
    jnum(member(input, "size_bytes")),
    options.limits.input_bytes,
    "input_bytes",
  )
  check_sha(jstr(member(input, "sha256")))
  let files = match member(j, "files").as_object() {
    Some(o) => o
    None => {
      reject("IntegrityMismatch", "Expected manifest file map")
      Map::new()
    }
  }
  let expected = if profile == "csv_with_canonical" {
    ["data.ndjson", "data.csv", "metadata.json", "codebook.md"]
  } else {
    ["data.ndjson", "metadata.json", "codebook.md"]
  }
  if files.length() != expected.length() {
    reject("IntegrityMismatch", "Manifest file set disagrees with profile")
  }
  let mut total = text.to_bytes().length()
  for name in expected {
    let f = match files.get(name) {
      Some(f) => f
      None => {
        reject("IntegrityMismatch", "Missing required manifest file")
        Json::null()
      }
    }
    let n = jnum(member(f, "size_bytes"))
    ignore(closed(f, ["size_bytes", "sha256"]))
    if n > options.limits.output_bytes - total {
      reject("ResourceLimit", "Bundle total bytes exceed limit")
    }
    total += n
    check_sha(jstr(member(f, "sha256")))
  }
  j
}

///|
fn check_sha(s : String) -> Unit raise SavError {
  if s.length() != 64 {
    reject("IntegrityMismatch", "Invalid SHA256")
  }
  for ch in s {
    let n = ch.to_int()
    if !((n >= 48 && n <= 57) || (n >= 97 && n <= 102)) {
      reject("IntegrityMismatch", "Invalid SHA256")
    }
  }
}

///|
pub struct BundleChecker {
  priv dictionary : Dictionary
  priv expected_rows : Int
  priv mut row : Int
  priv counts : Array[Array[Int]]
}

///|
pub fn BundleChecker::new(
  metadata : String,
  manifest : Json,
  options? : Options = Options::default(),
) -> BundleChecker raise SavError {
  validate_limits(options.limits)
  ignore(check_manifest(manifest.stringify(), options~))
  let budget = DictionaryBudget::new(options.limits)
  let j = parse_json(metadata)
  if jstr(member(j, "schema_version")) != "moonsav.metadata/1" {
    reject("UnsupportedSchema", "Unsupported metadata schema")
  }
  if jstr(member(j, "validation_scope")) != "full" {
    reject("IncompleteBundle", "Metadata does not describe full validation")
  }
  let expected_rows = jnum(member(manifest, "actual_rows"))
  if jnum(member(j, "actual_rows")) != expected_rows {
    reject("IntegrityMismatch", "Metadata/manifest rows disagree")
  }
  let declared_rows = opt_int(member(j, "declared_rows"))
  if declared_rows is Some(n) && n != expected_rows {
    reject("IntegrityMismatch", "Declared and actual rows disagree")
  }
  let enc = closed(member(j, "encoding"), [
    "declared", "machine_code", "effective", "selection_source", "profile", "string_matching_policy",
    "decoder_identity",
  ])
  let effective_token = jstr(member(enc, "effective"))
  let effective = canonical_encoding(effective_token)
  if effective_token != effective {
    reject(
      "IntegrityMismatch", "Effective encoding must use its canonical serialized token",
    )
  }
  let profile = jstr(member(enc, "profile"))
  let policy = jstr(member(enc, "string_matching_policy"))
  if profile != effective + "/moonsav-1" ||
    policy != "source-bytes-space-padded-width-v1" {
    reject(
      "UnsupportedSchema", "Unknown encoding profile or string matching policy",
    )
  }
  let encoding : EncodingInfo = {
    declared: opt_str(member(enc, "declared")),
    machine_code: if member(enc, "machine_code") == Json::null() {
      None
    } else {
      Some(jsigned(member(enc, "machine_code")))
    },
    effective,
    profile,
    selection_source: jstr(member(enc, "selection_source")),
    string_matching_policy: policy,
    decoder_identity: jstr(member(enc, "decoder_identity")),
  }
  if encoding.decoder_identity.trim().is_empty() ||
    encoding.decoder_identity.contains("\x00") {
    reject(
      "IntegrityMismatch", "Decoder identity must be nonempty and NUL-free",
    )
  }
  if encoding.selection_source != "override" &&
    encoding.selection_source != "record20" &&
    encoding.selection_source != "machine_code" {
    reject("IntegrityMismatch", "Unknown encoding selection policy")
  }
  if encoding.selection_source != "override" {
    let chosen = encoding_info(encoding.declared, encoding.machine_code, {
      ..options,
      encoding_override: None,
    })
    if chosen.effective != encoding.effective ||
      chosen.selection_source != encoding.selection_source {
      reject(
        "IntegrityMismatch", "Encoding selection disagrees with declarations",
      )
    }
  }
  let csv_policy = closed(member(j, "csv"), [
    "numeric_system_missing", "string_escape", "date_policy", "encoding", "record_separator",
  ])
  for
    pair in [
      ("numeric_system_missing", "empty_field"),
      ("string_escape", "csv_quotes_only"),
      ("date_policy", "raw"),
      ("encoding", "utf-8"),
      ("record_separator", "CRLF"),
    ] {
    let (key, value) = pair
    if jstr(member(csv_policy, key)) != value {
      reject("IntegrityMismatch", "Unknown CSV/date representation policy")
    }
  }
  let dec = fn(b) raise SavError {
    let text = decode(b, effective, options)
    budget.decoded(text)
    text
  }
  for key in ["file_label", "creation_date", "creation_time", "product"] {
    budget.text(jstr(member(j, key)))
  }
  if encoding.declared is Some(text) {
    budget.text(text)
  }
  budget.text(encoding.decoder_identity)
  let system_missing_hex = jstr(member(j, "system_missing_hex"))
  let lowest_hex = jstr(member(j, "lowest_hex"))
  let highest_hex = jstr(member(j, "highest_hex"))
  for hex in [system_missing_hex, lowest_hex, highest_hex] {
    if !finite(parse_hex(hex).reinterpret_as_double()) {
      reject("IntegrityMismatch", "Invalid sentinel")
    }
  }
  let variables = []
  let aliases : Map[String, Int] = {}
  let var_json = jarr(member(j, "variables"))
  if var_json.length() != jnum(member(manifest, "logical_variables")) ||
    var_json.length() != jnum(member(j, "logical_variables")) {
    reject("IntegrityMismatch", "Variable counts disagree")
  }
  let mut slots = 0
  for item in var_json {
    let index = jnum(member(item, "index"))
    if index != variables.length() {
      reject("IntegrityMismatch", "Variable index/order mismatch")
    }
    let name = jstr(member(item, "name"))
    let short_name = jstr(member(item, "short_name"))
    budget.text(name)
    budget.text(short_name)
    for key in [name.to_upper(), short_name.to_upper()] {
      if key.is_empty() {
        reject("IntegrityMismatch", "Empty name")
      }
      if aliases.get(key) is Some(old) && old != index {
        reject("IntegrityMismatch", "Ambiguous variable alias")
      }
      aliases[key] = index
    }
    let kind = jstr(member(item, "type"))
    let width = jnum(member(item, "width"))
    if (kind != "numeric" && kind != "string") ||
      (kind == "numeric" && width != 0) ||
      (kind == "string" && width == 0) {
      reject("IntegrityMismatch", "Invalid variable type/width")
    }
    limit(width, options.limits.string_bytes, "string_bytes")
    let label = opt_str(member(item, "label"))
    let raw_label_base64 = opt_str(member(item, "raw_label_base64"))
    if (label == None) != (raw_label_base64 == None) {
      reject("IntegrityMismatch", "Label raw/text presence mismatch")
    }
    if label is Some(text) &&
      dec(dictionary_b64(raw_label_base64.unwrap(), budget, label=true)) != text {
      reject("IntegrityMismatch", "Label raw bytes/text mismatch")
    }
    let labels : Array[ValueLabel] = []
    let label_json = jarr(member(item, "value_labels"))
    budget.labels(label_json.length())
    for entry in label_json {
      ignore(closed(entry, ["value", "label", "raw_label_base64"]))
      let value = parsed_atom(member(entry, "value"), kind, dec, budget)
      let text = jstr(member(entry, "label"))
      let raw = jstr(member(entry, "raw_label_base64"))
      if dec(dictionary_b64(raw, budget, label=true)) != text {
        reject("IntegrityMismatch", "Value label raw bytes/text mismatch")
      }
      labels.push({ value, label: text, raw_label_base64: raw })
    }
    let missing = closed(member(item, "user_missing"), ["kind", "values"])
    let missing_kind = jstr(member(missing, "kind"))
    let missing_values = jarr(member(missing, "values")).map(a => {
      parsed_atom(a, kind, dec, budget)
    })
    if missing_kind == "discrete" {
      if missing_values.length() > 3 {
        reject("IntegrityMismatch", "Too many discrete missing values")
      }
    } else if (
        (missing_kind == "range" && missing_values.length() == 2) ||
        (missing_kind == "range_plus_discrete" && missing_values.length() == 3)
      ) &&
      kind == "numeric" {
      if atom_number(missing_values[0]) > atom_number(missing_values[1]) {
        reject("IntegrityMismatch", "Reversed missing range")
      }
    } else {
      reject("IntegrityMismatch", "Invalid missing rule")
    }
    let physical_start = jnum(member(item, "physical_start"))
    let physical_slots = jnum(member(item, "physical_slots"))
    if physical_start != slots || physical_slots == 0 {
      reject(
        "IntegrityMismatch", "Physical slot ranges overlap or contain gaps",
      )
    }
    if physical_slots > options.limits.physical_slots - slots {
      reject("ResourceLimit", "physical_slots exceed limit")
    }
    slots += physical_slots
    variables.push({
      index,
      name,
      short_name,
      type_: kind,
      width,
      label,
      raw_label_base64,
      source_offset: jnum(member(item, "source_offset")),
      physical_start,
      physical_slots,
      print_format: parsed_format(member(item, "print_format")),
      write_format: parsed_format(member(item, "write_format")),
      value_labels: labels,
      missing_kind,
      missing_values,
      measure: opt_int(member(item, "measure")),
      display_width: opt_int(member(item, "display_width")),
      alignment: opt_int(member(item, "alignment")),
      segments: [],
    })
  }
  if slots != jnum(member(j, "physical_slots")) {
    reject("IntegrityMismatch", "Physical slot total mismatch")
  }
  let nominal_case_size = jsigned(member(j, "nominal_case_size"), minimum=-1.0)
  validate_case_width(nominal_case_size, variables, slots, "IntegrityMismatch")
  let compression = jnum(member(j, "compression"))
  if compression > 1 {
    reject("IntegrityMismatch", "Invalid compression metadata")
  }
  let bias = match member(j, "bias").as_number() {
    Some(n) => n
    None => {
      reject("IntegrityMismatch", "Expected numeric bias")
      0.0
    }
  }
  if !finite(bias) {
    reject("IntegrityMismatch", "Compression bias must be finite")
  }
  let warnings = []
  for w in jarr(member(j, "warnings")) {
    ignore(closed(w, ["warning_code", "scope", "suggested_action"]))
    warnings.push({
      warning_code: jstr(member(w, "warning_code")),
      scope: jstr(member(w, "scope")),
      suggested_action: jstr(member(w, "suggested_action")),
    })
  }
  let extras = []
  let mut extra_bytes = 0
  for e in jarr(member(j, "uninterpreted_metadata")) {
    ignore(closed(e, ["record", "subtype", "byte_offset", "raw_base64"]))
    let record = jnum(member(e, "record"))
    let subtype = opt_int(member(e, "subtype"))
    let offset = jnum(member(e, "byte_offset"))
    let raw = jstr(member(e, "raw_base64"))
    let bytes = dictionary_b64(raw, budget, extension=true)
    if record == 7 {
      match subtype {
        Some(5 | 6 | 7 | 8 | 9 | 10 | 12 | 17 | 18 | 19 | 24) => ()
        _ => reject("IntegrityMismatch", "Unknown retained semantic extension")
      }
    } else if record != 6 || subtype != None {
      reject("IntegrityMismatch", "Invalid uninterpreted metadata record")
    }
    if bytes.length() > options.limits.extension_bytes ||
      bytes.length() > options.limits.dictionary_bytes - extra_bytes {
      reject("ResourceLimit", "Retained metadata exceeds dictionary budget")
    }
    extra_bytes += bytes.length()
    extras.push({ record, subtype, byte_offset: offset, raw_base64: raw })
  }
  if !extras.is_empty() &&
    !warnings.any(w => w.warning_code == "UninterpretedMetadata") {
    reject("IntegrityMismatch", "Uninterpreted metadata warning is missing")
  }
  if encoding.selection_source == "override" &&
    !warnings.any(w => w.warning_code == "EncodingOverride") {
    reject("IntegrityMismatch", "Encoding override warning is missing")
  }
  validate_variables(
    variables,
    lowest_hex,
    highest_hex,
    "IntegrityMismatch",
    options.limits,
  )
  let weight = opt_int(member(j, "weight_variable"))
  if weight is Some(index) &&
    (index >= variables.length() || variables[index].type_ != "numeric") {
    reject("IntegrityMismatch", "Invalid weight variable reference")
  }
  let dictionary : Dictionary = {
    variables,
    declared_rows,
    compression,
    bias,
    physical_slots: slots,
    nominal_case_size,
    encoding,
    file_label: jstr(member(j, "file_label")),
    creation_date: jstr(member(j, "creation_date")),
    creation_time: jstr(member(j, "creation_time")),
    product: jstr(member(j, "product")),
    weight_variable: opt_int(member(j, "weight_variable")),
    warnings,
    uninterpreted_metadata: extras,
    system_missing_hex,
    lowest_hex,
    highest_hex,
    data_offset: 0,
    options,
  }
  {
    dictionary,
    expected_rows,
    row: 0,
    counts: Array::makei(variables.length(), _ => [0, 0, 0]),
  }
}

///|
pub fn BundleChecker::dictionary_json(self : BundleChecker) -> Json {
  self.dictionary.to_json()
}

///|
pub fn BundleChecker::header(
  self : BundleChecker,
  csv : String,
) -> Unit raise SavError {
  if parse_csv(csv) != self.dictionary.variables.map(v => v.name) {
    reject("IntegrityMismatch", "CSV header/order differs from dictionary")
  }
}

///|
pub fn BundleChecker::next(
  self : BundleChecker,
  line : String,
  csv? : String? = None,
) -> Unit raise SavError {
  if self.row >= self.expected_rows {
    reject("IntegrityMismatch", "Too many canonical rows")
  }
  let j = closed(parse_json(line), ["row", "cells"])
  if jnum(member(j, "row")) != self.row {
    reject("IntegrityMismatch", "Canonical row sequence mismatch")
  }
  let cells = jarr(member(j, "cells"))
  if cells.length() != self.dictionary.variables.length() {
    reject("IntegrityMismatch", "Wrong canonical column count")
  }
  let visible = []
  for i = 0; i < cells.length(); i = i + 1 {
    let j = closed(cells[i], [
      "kind", "missing", "decimal", "ieee754_hex", "text", "logical_bytes_base64",
    ])
    let v = self.dictionary.variables[i]
    let kind = jstr(member(j, "kind"))
    let missing = jstr(member(j, "missing"))
    if kind != v.type_ ||
      (missing != "present" && missing != "user" && missing != "system") {
      reject("IntegrityMismatch", "Wrong cell kind/missing state")
    }
    let decimal = opt_str(member(j, "decimal"))
    let hex = opt_str(member(j, "ieee754_hex"))
    let text = opt_str(member(j, "text"))
    let raw = opt_str(member(j, "logical_bytes_base64"))
    if kind == "numeric" {
      if hex == None || text != None || raw != None {
        reject("IntegrityMismatch", "Invalid numeric cell fields")
      }
      let bits = parse_hex(hex.unwrap())
      let system = hex == Some(self.dictionary.system_missing_hex)
      if system {
        if missing != "system" || decimal != None {
          reject("IntegrityMismatch", "System missing fields disagree")
        }
        visible.push("")
      } else {
        if missing == "system" || decimal == None {
          reject("IntegrityMismatch", "Numeric missing state/decimal mismatch")
        }
        jdecimal(decimal.unwrap(), bits)
        let expected = if user_missing(v, Some(bits), None) {
          "user"
        } else {
          "present"
        }
        if missing != expected {
          reject(
            "IntegrityMismatch", "Numeric user missing state disagrees with dictionary",
          )
        }
        visible.push(decimal.unwrap())
      }
    } else {
      if decimal != None ||
        hex != None ||
        text == None ||
        raw == None ||
        missing == "system" {
        reject("IntegrityMismatch", "Invalid string cell fields")
      }
      let bytes = b64(raw.unwrap())
      if bytes.length() != v.width {
        reject("IntegrityMismatch", "String logical byte width mismatch")
      }
      if decode(
          bytes,
          self.dictionary.encoding.effective,
          self.dictionary.options,
        ) !=
        text.unwrap() {
        reject("IntegrityMismatch", "String bytes and decoded text disagree")
      }
      let expected = if user_missing(v, None, Some(bytes)) {
        "user"
      } else {
        "present"
      }
      if missing != expected {
        reject(
          "IntegrityMismatch", "String missing state disagrees with byte-key rule",
        )
      }
      visible.push(text.unwrap())
    }
    let index = match missing {
      "present" => 0
      "user" => 1
      _ => 2
    }
    self.counts[i][index] += 1
  }
  if csv is Some(record) && parse_csv(record) != visible {
    reject(
      "IntegrityMismatch", "CSV visible values disagree with canonical row",
    )
  }
  self.row += 1
}

///|
pub fn BundleChecker::finish(
  self : BundleChecker,
) -> ScanSummary raise SavError {
  if self.row != self.expected_rows {
    reject("IntegrityMismatch", "Canonical row count mismatch")
  }
  {
    actual_rows: self.row,
    completed: true,
    counts: self.counts.map(row => row.copy()),
  }
}

///|
fn parse_csv(record : String) -> Array[String] raise SavError {
  let chars = record.to_array()
  let out = []
  let field = StringBuilder::new()
  let mut state = 0
  let mut i = 0
  // state 0 unquoted, 1 quoted, 2 after quote; CRLF outside quotes terminates exactly one record.
  while i < chars.length() {
    let ch = chars[i]
    if ch == '\x00' {
      reject("IntegrityMismatch", "NUL is not allowed in CSV profile")
    }
    if state == 1 {
      if ch == '"' {
        if i + 1 < chars.length() && chars[i + 1] == '"' {
          field.write_char('"')
          i += 1
        } else {
          state = 2
        }
      } else {
        field.write_char(ch)
      }
    } else if ch == ',' {
      out.push(field.to_string())
      field.reset()
      state = 0
    } else if ch == '\r' {
      if i + 2 != chars.length() || chars[i + 1] != '\n' {
        reject("IntegrityMismatch", "Invalid CSV record separator")
      }
      out.push(field.to_string())
      return out
    } else if ch == '\n' || state == 2 {
      reject("IntegrityMismatch", "Invalid CSV quoting or newline")
    } else if ch == '"' {
      if !field.is_empty() {
        reject("IntegrityMismatch", "Quote inside unquoted CSV field")
      }
      state = 1
    } else {
      field.write_char(ch)
    }
    i += 1
  }
  reject("IntegrityMismatch", "Unterminated CSV record")
  []
}
