///|
pub(all) struct SavAttribute {
  name : String
  values : Array[String]
} derive(ToJson)

///|
pub(all) struct SavVariableAttributes {
  variable_index : Int
  attributes : Array[SavAttribute]
} derive(ToJson)

///|
pub(all) struct SavVariableSet {
  name : String
  variable_indices : Array[Int]
} derive(ToJson)

///|
pub(all) struct SavMultipleResponseSet {
  name : String
  kind : String
  category_labels : String?
  label_source : String?
  counted_value : String?
  label : String?
  variable_indices : Array[Int]
}

///|
pub(all) struct DictionaryAnnotations {
  document_lines : Array[String]
  variable_sets : Array[SavVariableSet]
  file_attributes : Array[SavAttribute]
  variable_attributes : Array[SavVariableAttributes]
  multiple_response_sets : Array[SavMultipleResponseSet]
  sources : Array[Extra]
} derive(ToJson)

///|
fn DictionaryAnnotations::empty() -> DictionaryAnnotations {
  {
    document_lines: [],
    variable_sets: [],
    file_attributes: [],
    variable_attributes: [],
    multiple_response_sets: [],
    sources: [],
  }
}

///|
fn annotation_error() -> Unit raise SavError {
  reject("InvalidAnnotation", "Unrecognized dictionary annotation layout")
}

///|
fn split_annotation(
  text : StringView,
  delimiter : StringView,
) -> (StringView, StringView) raise SavError {
  match text.split_once(delimiter) {
    Some(pair) => pair
    None => {
      annotation_error()
      ("", "")
    }
  }
}

///|
fn annotation_name(s : StringView) -> String raise SavError {
  if s.is_empty() ||
    s.any(c => {
      c == ' ' ||
      c == '\t' ||
      c == '\r' ||
      c == '\n' ||
      c == '/' ||
      c == ':' ||
      c == '=' ||
      c == '(' ||
      c == ')' ||
      c == '\u0000'
    }) {
    annotation_error()
  }
  s.to_owned()
}

///|
fn annotation_index(
  token : StringView,
  indices : Map[String, Int],
) -> Int raise SavError {
  let name = annotation_name(token)
  match indices.get(name.to_upper()) {
    Some(index) => index
    None => {
      annotation_error()
      0
    }
  }
}

///|
fn parse_attribute_set(
  input : StringView,
  budget : DictionaryBudget,
) -> (Array[SavAttribute], StringView) raise SavError {
  let attributes = []
  let mut rest = input
  while !rest.is_empty() && !rest.has_prefix("/") {
    let (token, body) = split_annotation(rest, "(")
    let name = annotation_name(token)
    let values = []
    rest = body
    while rest.has_prefix("'") {
      let (line, next) = split_annotation(rest, "\n")
      if line.length() < 2 || !line.has_suffix("'") {
        annotation_error()
      }
      budget.labels(1)
      values.push(line[1:line.length() - 1].to_owned())
      rest = next
    }
    if values.is_empty() {
      annotation_error()
    }
    match rest.strip_prefix(")") {
      Some(next) => rest = next
      None => annotation_error()
    }
    budget.labels(1)
    attributes.push({ name, values })
  }
  (attributes, rest)
}

///|
fn annotation_indices(variables : Array[Variable]) -> Map[String, Int] {
  let indices = Map([])
  for v in variables {
    indices[v.name.to_upper()] = v.index
    indices[v.short_name.to_upper()] = v.index
  }
  indices
}

///|
fn annotation_until(c : Cursor, delimiter : Byte) -> Bytes raise SavError {
  let start = c.pos
  while c.pos < c.bytes.length() && c.bytes[c.pos] != delimiter {
    if c.bytes[c.pos] == b'\n' {
      annotation_error()
    }
    c.pos += 1
  }
  let end = c.pos
  if end == c.bytes.length() && delimiter != b'\n' {
    annotation_error()
  }
  if end < c.bytes.length() {
    c.pos += 1
  }
  c.bytes[start:end].to_owned()
}

///|
fn annotation_byte(c : Cursor) -> Byte raise SavError {
  if c.pos == c.bytes.length() {
    annotation_error()
  }
  c.take(1)[0]
}

///|
fn annotation_space(c : Cursor) -> Unit raise SavError {
  if annotation_byte(c) != b' ' {
    annotation_error()
  }
}

///|
fn annotation_sized(
  c : Cursor,
  dec : (Bytes) -> String raise SavError,
  budget : DictionaryBudget,
) -> String raise SavError {
  let length_bytes = annotation_until(c, b' ')
  if length_bytes.is_empty() {
    annotation_error()
  }
  let mut size = 0
  for b in length_bytes {
    if b < b'0' || b > b'9' || size > budget.limits.label_bytes / 10 {
      annotation_error()
    }
    size = size * 10 + b.to_int() - b'0'.to_int()
  }
  limit(size, budget.limits.label_bytes, "annotation label bytes")
  if size > c.bytes.length() - c.pos {
    annotation_error()
  }
  dec(c.take(size))
}

///|
fn multiple_response_sets(
  bytes : Bytes,
  indices : Map[String, Int],
  dec : (Bytes) -> String raise SavError,
  budget : DictionaryBudget,
) -> Array[SavMultipleResponseSet] raise SavError {
  let c = Cursor::new(bytes)
  let sets = []
  while c.pos < bytes.length() {
    if bytes[c.pos] == b'\n' {
      c.pos += 1
      continue
    }
    let name = annotation_name(dec(annotation_until(c, b'='))[:])
    if !name.has_prefix("$") || name.length() == 1 {
      annotation_error()
    }
    let mode = annotation_byte(c)
    let mut label_source = None
    let (kind, category_labels, counted_value) = match mode {
      b'C' => {
        annotation_space(c)
        ("category", None, None)
      }
      b'D' =>
        (
          "dichotomy",
          Some("variable_labels"),
          Some(annotation_sized(c, dec, budget)),
        )
      b'E' => {
        annotation_space(c)
        let flag = annotation_until(c, b' ')
        if flag == b"11" {
          label_source = Some("variable_label")
        } else if flag != b"1" {
          annotation_error()
        }
        (
          "dichotomy",
          Some("counted_values"),
          Some(annotation_sized(c, dec, budget)),
        )
      }
      _ => {
        annotation_error()
        ("", None, None)
      }
    }
    if mode != b'C' {
      annotation_space(c)
    }
    let label_text = annotation_sized(c, dec, budget)
    let label = if label_text.is_empty() { None } else { Some(label_text) }
    let members = dec(annotation_until(c, b'\n'))
    let variable_indices = []
    for token in members.trim_end(chars="\r").split(" ") {
      if !token.is_empty() {
        budget.labels(1)
        variable_indices.push(annotation_index(token, indices))
      }
    }
    budget.labels(1)
    sets.push({
      name,
      kind,
      category_labels,
      label_source,
      counted_value,
      label,
      variable_indices,
    })
  }
  sets
}

///|
/// Parse one record before retaining it, so unfamiliar layouts can fall back atomically.
fn parse_annotation(
  a : DictionaryAnnotations,
  source : Extra,
  bytes : Bytes,
  indices : Map[String, Int],
  dec : (Bytes) -> String raise SavError,
  budget : DictionaryBudget,
) -> Unit raise SavError {
  match (source.record, source.subtype) {
    (6, None) => {
      if bytes.length() % 80 != 0 {
        annotation_error()
      }
      let lines = []
      for offset = 0; offset < bytes.length(); offset = offset + 80 {
        budget.labels(1)
        lines.push(dec(bytes[offset:offset + 80].to_owned()))
      }
      a.document_lines.append(lines)
    }
    (7, Some(5)) => {
      let sets = []
      let text = dec(bytes)
      for raw in text.split("\n") {
        let line = raw.strip_suffix("\r").unwrap_or(raw)
        if line.is_empty() {
          continue
        }
        let (name, members) = split_annotation(line, "= ")
        let variable_indices = []
        for token in members.split(" ") {
          if !token.is_empty() {
            budget.labels(1)
            variable_indices.push(annotation_index(token, indices))
          }
        }
        budget.labels(1)
        sets.push({ name: annotation_name(name), variable_indices })
      }
      a.variable_sets.append(sets)
    }
    (7, Some(7 | 19)) =>
      a.multiple_response_sets.append(
        multiple_response_sets(bytes, indices, dec, budget),
      )
    (7, Some(17)) => {
      let text = dec(bytes)
      let (attributes, rest) = parse_attribute_set(text[:], budget)
      if attributes.is_empty() || !rest.is_empty() {
        annotation_error()
      }
      a.file_attributes.append(attributes)
    }
    (7, Some(18)) => {
      let groups = []
      let text = dec(bytes)
      let mut rest = text[:]
      while !rest.is_empty() {
        let (name, body) = split_annotation(rest, ":")
        let variable_index = annotation_index(name, indices)
        let (attributes, next) = parse_attribute_set(body, budget)
        if attributes.is_empty() {
          annotation_error()
        }
        budget.labels(1)
        groups.push({ variable_index, attributes })
        rest = next.strip_prefix("/").unwrap_or(next)
      }
      if groups.is_empty() {
        annotation_error()
      }
      a.variable_attributes.append(groups)
    }
    _ => annotation_error()
  }
  a.sources.push(source)
}
