///|
fn atom_json(a : Atom) -> Json {
  {
    "type": a.type_.to_json(),
    "decimal": optional(a.decimal),
    "ieee754_hex": optional(a.ieee754_hex),
    "text": optional(a.text),
    "logical_bytes_base64": optional(a.logical_bytes_base64),
    "width": a.width.to_json(),
    "endpoint": optional(a.endpoint),
  }
}

///|
pub impl ToJson for Variable with fn to_json(self : Variable) -> Json {
  {
    "index": self.index.to_json(),
    "name": self.name.to_json(),
    "short_name": self.short_name.to_json(),
    "type": self.type_.to_json(),
    "width": self.width.to_json(),
    "label": optional(self.label),
    "raw_label_base64": optional(self.raw_label_base64),
    "source_offset": self.source_offset.to_json(),
    "physical_start": self.physical_start.to_json(),
    "physical_slots": self.physical_slots.to_json(),
    "print_format": self.print_format.to_json(),
    "write_format": self.write_format.to_json(),
    "value_labels": self.value_labels
    .map(x => {
      (
        {
          "value": atom_json(x.value),
          "label": x.label.to_json(),
          "raw_label_base64": x.raw_label_base64.to_json(),
        } : Json)
    })
    .to_json(),
    "user_missing": (
      {
        "kind": self.missing_kind.to_json(),
        "values": self.missing_values.map(atom_json).to_json(),
      } : Json),
    "measure": optional(self.measure),
    "display_width": optional(self.display_width),
    "alignment": optional(self.alignment),
  }
}

///|
pub impl ToJson for Dictionary with fn to_json(self : Dictionary) -> Json {
  {
    "schema_version": "moonsav.metadata/1",
    "validation_scope": "dictionary_only",
    "declared_rows": optional(self.declared_rows),
    "actual_rows": Json::null(),
    "logical_variables": self.variables.length().to_json(),
    "variables": self.variables.map(v => v.to_json()).to_json(),
    "encoding": self.encoding.to_json(),
    "file_label": self.file_label.to_json(),
    "creation_date": self.creation_date.to_json(),
    "creation_time": self.creation_time.to_json(),
    "product": self.product.to_json(),
    "weight_variable": optional(self.weight_variable),
    "compression": self.compression.to_json(),
    "bias": self.bias.to_json(),
    "physical_slots": self.physical_slots.to_json(),
    "nominal_case_size": self.nominal_case_size.to_json(),
    "system_missing_hex": self.system_missing_hex.to_json(),
    "lowest_hex": self.lowest_hex.to_json(),
    "highest_hex": self.highest_hex.to_json(),
    "warnings": self.warnings.to_json(),
    "uninterpreted_metadata": self.uninterpreted_metadata.to_json(),
    "csv": (
      {
        "numeric_system_missing": "empty_field",
        "string_escape": "csv_quotes_only",
        "date_policy": "raw",
        "encoding": "utf-8",
        "record_separator": "CRLF",
      } : Json),
  }
}

///|
pub fn metadata_json(d : Dictionary, actual_rows : Int) -> Json {
  let obj = match d.to_json() {
    Object(obj) => obj
    _ => abort("object")
  }
  obj["validation_scope"] = "full"
  obj["actual_rows"] = actual_rows.to_json()
  Json::object(obj)
}

///|
pub fn row_json(row : Array[Cell], index : Int) -> String {
  ({ "row": index.to_json(), "cells": row.to_json() } : Json).stringify() + "\n"
}

///|
fn csv_quote(value : String, force? : Bool = false) -> String {
  if force ||
    value.contains(",") ||
    value.contains("\"") ||
    value.contains("\r") ||
    value.contains("\n") {
    "\"" + value.replace(old="\"", new="\"\"") + "\""
  } else {
    value
  }
}

///|
pub fn csv_header(d : Dictionary) -> String {
  d.variables.map(v => csv_quote(v.name)).join(",") + "\r\n"
}

///|
pub fn csv_row(row : Array[Cell]) -> String raise SavError {
  let out = []
  for cell in row {
    if cell.kind == "numeric" {
      out.push(
        if cell.missing == "system" {
          "\"\""
        } else {
          cell.decimal.unwrap()
        },
      )
    } else {
      let text = cell.text.unwrap()
      if text.contains("\x00") {
        reject(
          "ExportRepresentationError", "NUL cannot be represented in CSV; retry --format ndjson",
        )
      }
      out.push(csv_quote(text))
    }
  }
  out.join(",") + "\r\n"
}

///|
fn md_text(s : String) -> String {
  s
  .replace(old="\\", new="\\\\")
  .replace(old="|", new="\\|")
  .replace(old="*", new="\\*")
  .replace(old="_", new="\\_")
  .replace(old="[", new="\\[")
  .replace(old="]", new="\\]")
  .replace(old="<", new="&lt;")
  .replace(old="\n", new=" ")
  .replace(old="\r", new=" ")
  .replace(old="`", new="\\`")
}

///|
pub fn codebook(d : Dictionary) -> String {
  let b = StringBuilder::new()
  b.write_string(
    "# MoonSav codebook\n\nCanonical data.ndjson preserves source bits/bytes and missing kinds. CSV is a standard text view; use metadata types and the supplied reader. Numeric system missing is an empty CSV field; strings NA, \\N, leading zeroes and spaces are text. Value labels never replace values. Dates retain raw numeric values and print/write formats. Spreadsheet import may infer numbers/dates or formulas: import as text. Hash checks are not source authentication.\n\n",
  )
  b.write_string(
    "Encoding: " +
    md_text(d.encoding.effective) +
    "; profile: " +
    md_text(d.encoding.profile) +
    "; matching: " +
    md_text(d.encoding.string_matching_policy) +
    ".\n\n",
  )
  for v in d.variables {
    b.write_string("## " + md_text(v.name) + "\n\n")
    b.write_string(
      "Index " +
      v.index.to_string() +
      "; short name " +
      md_text(v.short_name) +
      "; storage " +
      v.type_ +
      "; logical byte width " +
      v.width.to_string() +
      ".\n\n",
    )
    b.write_string(
      "Label: " + md_text(v.label.unwrap_or("(not declared)")) + "\n\n",
    )
    b.write_string(
      "Print: " +
      v.print_format.to_json().stringify() +
      "; write: " +
      v.write_format.to_json().stringify() +
      ".\n\n",
    )
    b.write_string(
      "Missing: " +
      v.missing_kind +
      "; " +
      md_text(v.missing_values.map(atom_json).to_json().stringify()) +
      "\n\n",
    )
    b.write_string(
      "Measure/display/alignment: " +
      v.measure.to_json().stringify() +
      " / " +
      v.display_width.to_json().stringify() +
      " / " +
      v.alignment.to_json().stringify() +
      ".\n\n",
    )
    let n = if v.value_labels.length() > 10 {
      10
    } else {
      v.value_labels.length()
    }
    b.write_string(
      "Value labels (showing " +
      n.to_string() +
      " / total " +
      v.value_labels.length().to_string() +
      "; full table in metadata):\n\n",
    )
    for i = 0; i < n; i = i + 1 {
      let item = v.value_labels[i]
      b.write_string(
        "- " +
        md_text(atom_json(item.value).stringify()) +
        ": " +
        md_text(item.label) +
        "\n",
      )
    }
    b.write_string("\n")
  }
  b.to_string()
}

///|
fn[T : ToJson] optional(value : T?) -> Json {
  match value {
    Some(x) => x.to_json()
    None => Json::null()
  }
}

///|
pub impl ToJson for ErrorInfo with fn to_json(self : ErrorInfo) -> Json {
  {
    "code": self.code.to_json(),
    "message": self.message.to_json(),
    "byte_offset": optional(self.byte_offset),
    "record": optional(self.record),
    "subtype": optional(self.subtype),
    "variable_index": optional(self.variable_index),
    "row_index": optional(self.row_index),
    "actual": optional(self.actual),
    "limit": optional(self.limit),
  }
}

///|
pub impl ToJson for Cell with fn to_json(self : Cell) -> Json {
  {
    "kind": self.kind.to_json(),
    "missing": self.missing.to_json(),
    "decimal": optional(self.decimal),
    "ieee754_hex": optional(self.ieee754_hex),
    "text": optional(self.text),
    "logical_bytes_base64": optional(self.logical_bytes_base64),
  }
}

///|
pub impl ToJson for EncodingInfo with fn to_json(self : EncodingInfo) -> Json {
  {
    "declared": optional(self.declared),
    "machine_code": optional(self.machine_code),
    "effective": self.effective.to_json(),
    "selection_source": self.selection_source.to_json(),
    "profile": self.profile.to_json(),
    "string_matching_policy": self.string_matching_policy.to_json(),
    "decoder_identity": self.decoder_identity.to_json(),
  }
}

///|
pub impl ToJson for Extra with fn to_json(self : Extra) -> Json {
  {
    "record": self.record.to_json(),
    "subtype": optional(self.subtype),
    "byte_offset": self.byte_offset.to_json(),
    "raw_base64": self.raw_base64.to_json(),
  }
}

///|
pub impl ToJson for Atom with fn to_json(self : Atom) -> Json {
  atom_json(self)
}
