///|
pub(all) struct ErrorInfo {
  code : String
  message : String
  byte_offset : Int?
  record : Int?
  subtype : Int?
  variable_index : Int?
  row_index : Int?
  actual : Int?
  limit : Int?
} derive(Debug)

///|
pub(all) suberror SavError {
  SavFailure(ErrorInfo)
} derive(Debug)

///|
fn reject(
  code : String,
  message : String,
  offset? : Int = -1,
  row? : Int = -1,
  variable? : Int = -1,
  actual? : Int = -1,
  maximum? : Int = -1,
) -> Unit raise SavError {
  raise SavFailure({
    code,
    message,
    record: None,
    subtype: None,
    variable_index: if variable < 0 {
      None
    } else {
      Some(variable)
    },
    row_index: if row < 0 {
      None
    } else {
      Some(row)
    },
    actual: if actual < 0 {
      None
    } else {
      Some(actual)
    },
    limit: if maximum < 0 {
      None
    } else {
      Some(maximum)
    },
    byte_offset: if offset < 0 {
      None
    } else {
      Some(offset)
    },
  })
}

///|
pub fn SavError::info(self : SavError) -> ErrorInfo {
  let SavFailure(info) = self
  info
}

///|
pub(all) struct Limits {
  input_bytes : Int
  dictionary_bytes : Int
  variables : Int
  physical_slots : Int
  string_bytes : Int
  label_bytes : Int
  extension_bytes : Int
  row_bytes : Int
  rows : Int
  cells : Int
  retained_bytes : Int
  output_bytes : Int
} derive(Debug, ToJson)

///|
pub fn Limits::default() -> Limits {
  {
    input_bytes: 268435456,
    dictionary_bytes: 67108864,
    variables: 100000,
    physical_slots: 1000000,
    string_bytes: 32767,
    label_bytes: 1048576,
    extension_bytes: 16777216,
    row_bytes: 8388608,
    rows: 1000000,
    cells: 5000000,
    retained_bytes: 134217728,
    output_bytes: 536870912,
  }
}

///|
pub(all) enum DatePolicy {
  Raw
} derive(Debug, Eq)

///|
pub(all) struct Options {
  date_policy : DatePolicy
  limits : Limits
  encoding_override : String?
  decoder_identity : String?
  decoder : ((Bytes, String) -> String raise SavError)?
}

///|
pub fn Options::default() -> Options {
  {
    date_policy: Raw,
    limits: Limits::default(),
    encoding_override: None,
    decoder_identity: None,
    decoder: None,
  }
}

///|
pub(all) struct Format {
  raw : Int
  code : Int
  width : Int
  decimals : Int
} derive(Debug, ToJson)

///|
fn format(raw : Int) -> Format {
  { raw, code: (raw >> 16) & 255, width: (raw >> 8) & 255, decimals: raw & 255 }
}

///|
pub(all) struct Atom {
  type_ : String
  decimal : String?
  ieee754_hex : String?
  text : String?
  logical_bytes_base64 : String?
  width : Int
  endpoint : String?
} derive(Debug, Eq)

///|
pub(all) struct ValueLabel {
  value : Atom
  label : String
  raw_label_base64 : String
} derive(Debug, ToJson)

///|
pub(all) struct Variable {
  index : Int
  short_name : String
  name : String
  type_ : String
  width : Int
  label : String?
  raw_label_base64 : String?
  source_offset : Int
  physical_start : Int
  physical_slots : Int
  print_format : Format
  write_format : Format
  value_labels : Array[ValueLabel]
  missing_kind : String
  missing_values : Array[Atom]
  measure : Int?
  display_width : Int?
  alignment : Int?
  priv segments : Array[(Int, Int)]
} derive(Debug)

///|
pub(all) struct EncodingInfo {
  declared : String?
  machine_code : Int?
  effective : String
  selection_source : String
  profile : String
  string_matching_policy : String
  decoder_identity : String
} derive(Debug)

///|
pub(all) struct Warning {
  warning_code : String
  scope : String
  suggested_action : String
} derive(Debug, ToJson)

///|
pub(all) struct Extra {
  record : Int
  subtype : Int?
  byte_offset : Int
  raw_base64 : String
} derive(Debug)

///|
pub(all) struct Dictionary {
  variables : Array[Variable]
  declared_rows : Int?
  compression : Int
  bias : Double
  physical_slots : Int
  nominal_case_size : Int
  encoding : EncodingInfo
  file_label : String
  creation_date : String
  creation_time : String
  product : String
  weight_variable : Int?
  warnings : Array[Warning]
  uninterpreted_metadata : Array[Extra]
  system_missing_hex : String
  lowest_hex : String
  highest_hex : String
  priv data_offset : Int
  priv options : Options
}

///|
pub(all) struct Cell {
  kind : String
  missing : String
  decimal : String?
  ieee754_hex : String?
  text : String?
  logical_bytes_base64 : String?
} derive(Debug)

///|
pub fn Cell::missing_kind(self : Cell) -> String {
  self.missing
}

///|
pub fn Cell::is_missing(self : Cell) -> Bool {
  self.missing != "present"
}

///|
pub(all) struct Dataset {
  dictionary : Dictionary
  rows : Array[Array[Cell]]
}

///|
pub(all) enum ScanControl {
  Continue
  Stop
} derive(Debug, Eq)

///|
pub(all) struct ScanSummary {
  actual_rows : Int
  completed : Bool
  counts : Array[Array[Int]]
} derive(Debug, ToJson)

///|
fn limit(n : Int, max : Int, key : String) -> Unit raise SavError {
  if n < 0 || n > max {
    if n < 0 {
      reject("InvalidLength", "Negative declared length", actual=n)
    }
    reject(
      "ResourceLimit",
      "\{key}: actual \{n}, limit \{max}",
      actual=n,
      maximum=max,
    )
  }
}

///|
fn numeric_atom(
  bits : UInt64,
  endpoint? : String? = None,
) -> Atom raise SavError {
  if !finite(bits.reinterpret_as_double()) {
    reject("UnsupportedNumeric", "Non-finite numeric atom")
  }
  {
    type_: "numeric",
    decimal: Some(decimal(bits)),
    ieee754_hex: Some(hex_bits(bits)),
    text: None,
    logical_bytes_base64: None,
    width: 8,
    endpoint,
  }
}

///|
fn string_atom(
  bytes : Bytes,
  d : (Bytes) -> String raise SavError,
) -> Atom raise SavError {
  {
    type_: "string",
    decimal: None,
    ieee754_hex: None,
    text: Some(d(bytes)),
    logical_bytes_base64: Some(@base64.encode(bytes)),
    width: bytes.length(),
    endpoint: None,
  }
}

///|
fn validate_limits(l : Limits) -> Unit raise SavError {
  let hard = Limits::default()
  let values = [
    l.input_bytes,
    l.dictionary_bytes,
    l.variables,
    l.physical_slots,
    l.string_bytes,
    l.label_bytes,
    l.extension_bytes,
    l.row_bytes,
    l.rows,
    l.cells,
    l.retained_bytes,
    l.output_bytes,
  ]
  let maxima = [
    hard.input_bytes,
    hard.dictionary_bytes,
    hard.variables,
    hard.physical_slots,
    hard.string_bytes,
    hard.label_bytes,
    hard.extension_bytes,
    hard.row_bytes,
    hard.rows,
    hard.cells,
    hard.retained_bytes,
    hard.output_bytes,
  ]
  for i = 0; i < values.length(); i = i + 1 {
    if values[i] <= 0 || values[i] > maxima[i] {
      reject(
        "ResourceLimit", "Limits must be positive and can only lower compiled maxima",
      )
    }
  }
}
