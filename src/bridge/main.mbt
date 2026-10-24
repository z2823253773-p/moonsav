///|
extern "js" fn platform_decoder_identity() -> String =
  #| () => 'Node TextDecoder '+process.version+' / ICU '+process.versions.icu+' / MoonSav frozen mapping guards v1'

///|
extern "js" fn platform_decode(bytes : Bytes, encoding : String) -> String =
  #| (bytes, encoding) => globalThis.__moonsavDecode(bytes, encoding)

///|
extern "js" fn platform_emit(kind : String, payload : String) -> String =
  #| (kind, payload) => { try { globalThis.__moonsavEmit(kind, payload); return ''; } catch (_) { return 'Sink failed'; } }

///|
fn emit(kind : String, payload : String) -> Unit raise @moonsav.SavError {
  if platform_emit(kind, payload) != "" {
    raise @moonsav.SavFailure({
      code: "ConsumerFailed",
      message: "Output consumer failed",
      byte_offset: None,
      record: None,
      subtype: None,
      variable_index: None,
      row_index: None,
      actual: None,
      limit: None,
    })
  }
}

///|
pub fn run(
  input : Bytes,
  command : String,
  encoding : String,
  max_rows : Int,
  max_input : Int,
  max_output : Int,
) -> String {
  let limits = @moonsav.Limits::default()
  let options : @moonsav.Options = {
    date_policy: @moonsav.Raw,
    decoder_identity: Some(platform_decoder_identity()),
    limits: {
      ..limits,
      rows: max_rows,
      input_bytes: max_input,
      output_bytes: max_output,
    },
    encoding_override: if encoding == "" {
      None
    } else {
      Some(encoding)
    },
    decoder: Some(fn(bytes, enc) raise @moonsav.SavError {
      let s = platform_decode(bytes, enc)
      if s.has_prefix("\x00") {
        s[1:].to_owned()
      } else {
        raise @moonsav.SavFailure({
          code: if s.has_prefix("UnsupportedEncodingVariant") {
            "UnsupportedEncodingVariant"
          } else {
            "InvalidEncoding"
          },
          message: "Strict decoding failed for selected profile",
          byte_offset: None,
          record: None,
          subtype: None,
          variable_index: None,
          row_index: None,
          actual: None,
          limit: None,
        })
      }
    }),
  }
  let serialization_error : Ref[@moonsav.SavError?] = { val: None }
  try {
    if command == "inspect" {
      let d = @moonsav.inspect_bytes(input, options~)
      return ({ "ok": true, "dictionary": d.to_json() } : Json).stringify()
    }
    if command == "read" {
      let data = @moonsav.read_bytes(input, options~)
      for i = 0; i < data.rows.length(); i = i + 1 {
        emit("ndjson", @moonsav.row_json(data.rows[i], i))
      }
      return ({ "ok": true, "dictionary": data.dictionary.to_json() } : Json).stringify()
    }
    let index : Ref[Int] = { val: 0 }
    let dictionary : Ref[@moonsav.Dictionary?] = { val: None }
    let summary = @moonsav.scan_bytes(
      input,
      fn(d) raise {
        dictionary.val = Some(d)
        emit("dictionary", d.to_json().stringify())
        if command == "export-csv" {
          emit("csv", @moonsav.csv_header(d))
        }
      },
      fn(row) raise {
        if command == "read" ||
          command == "export-csv" ||
          command == "export-ndjson" {
          emit("ndjson", @moonsav.row_json(row, index.val))
          if command == "export-csv" {
            let csv = @moonsav.csv_row(row) catch {
              e => {
                serialization_error.val = Some(e)
                raise e
              }
            }
            emit("csv", csv)
          }
        }
        index.val += 1
        @moonsav.Continue
      },
      options~,
    )
    let d = dictionary.val.unwrap()
    if command == "export-csv" || command == "export-ndjson" {
      emit(
        "metadata",
        @moonsav.metadata_json(d, summary.actual_rows).stringify() + "\n",
      )
      emit("codebook", @moonsav.codebook(d))
    }
    (
      { "ok": true, "dictionary": d.to_json(), "summary": summary.to_json() } :
      Json).stringify()
  } catch {
    @moonsav.SavFailure(e) =>
      (
        {
          "ok": false,
          "error": match serialization_error.val {
            Some(s) => s.info().to_json()
            None => e.to_json()
          },
        } : Json).stringify()
  }
}

///|
fn main {

}

///|
let checker : Ref[@moonsav.BundleChecker?] = { val: None }

///|
fn checker_options(
  max_rows : Int,
  max_input : Int,
  max_output : Int,
) -> @moonsav.Options {
  let limits = @moonsav.Limits::default()
  {
    date_policy: @moonsav.Raw,
    decoder_identity: Some(platform_decoder_identity()),
    limits: {
      ..limits,
      rows: max_rows,
      input_bytes: max_input,
      output_bytes: max_output,
    },
    encoding_override: None,
    decoder: Some(fn(bytes, enc) raise @moonsav.SavError {
      let text = platform_decode(bytes, enc)
      if text.has_prefix("\x00") {
        text[1:].to_owned()
      } else {
        raise @moonsav.SavFailure({
          code: if text.has_prefix("UnsupportedEncodingVariant") {
            "UnsupportedEncodingVariant"
          } else {
            "InvalidEncoding"
          },
          message: "Strict profile decoding failed",
          byte_offset: None,
          record: None,
          subtype: None,
          variable_index: None,
          row_index: None,
          actual: None,
          limit: None,
        })
      }
    }),
  }
}

///|
pub fn check_manifest_bridge(
  text : String,
  max_rows : Int,
  max_input : Int,
  max_output : Int,
) -> String {
  try {
    let manifest = @moonsav.check_manifest(
      text,
      options=checker_options(max_rows, max_input, max_output),
    )
    ({ "ok": true, "manifest": manifest } : Json).stringify()
  } catch {
    @moonsav.SavFailure(e) =>
      ({ "ok": false, "error": e.to_json() } : Json).stringify()
  }
}

///|
pub fn check_start_bridge(
  metadata : String,
  manifest : String,
  max_rows : Int,
  max_input : Int,
  max_output : Int,
) -> String {
  try {
    let options = checker_options(max_rows, max_input, max_output)
    let m = @moonsav.check_manifest(manifest, options~)
    let c = @moonsav.BundleChecker::new(metadata, m, options~)
    checker.val = Some(c)
    ({ "ok": true, "dictionary": c.dictionary_json() } : Json).stringify()
  } catch {
    @moonsav.SavFailure(e) =>
      ({ "ok": false, "error": e.to_json() } : Json).stringify()
  }
}

///|
pub fn check_row_bridge(line : String, csv : String, mode : Int) -> String {
  try {
    let c = checker.val.unwrap()
    if mode == 1 {
      c.header(csv)
    } else {
      c.next(line, csv=if mode == 2 { Some(csv) } else { None })
    }
    ({ "ok": true } : Json).stringify()
  } catch {
    @moonsav.SavFailure(e) =>
      ({ "ok": false, "error": e.to_json() } : Json).stringify()
  }
}

///|
pub fn check_end_bridge() -> String {
  try {
    let c = checker.val.unwrap()
    let summary = c.finish()
    checker.val = None
    ({ "ok": true, "summary": summary.to_json() } : Json).stringify()
  } catch {
    @moonsav.SavFailure(e) =>
      ({ "ok": false, "error": e.to_json() } : Json).stringify()
  }
}
