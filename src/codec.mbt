///|
fn canonical_encoding(name : String) -> String raise SavError {
  match name.to_lower().trim().to_owned() {
    "utf-8" | "utf8" | "65001" => "utf-8"
    "windows-1252" | "cp1252" | "1252" => "windows-1252"
    "gbk" | "cp936" | "936" => "gbk"
    "gb18030" | "54936" => "gb18030"
    _ => {
      reject(
        "UnsupportedEncoding", "Encoding is outside the explicit whitelist",
      )
      ""
    }
  }
}

///|
fn decode(
  bytes : Bytes,
  encoding : String,
  options : Options,
) -> String raise SavError {
  match options.decoder {
    Some(d) => d(bytes, encoding)
    None => {
      if encoding != "utf-8" {
        reject(
          "UnsupportedEncoding", "This backend requires a verified decoder adapter",
        )
      }
      @utf8.decode(bytes[:], ignore_bom=false) catch {
        _ => {
          reject("InvalidEncoding", "Invalid UTF-8 byte sequence")
          ""
        }
      }
    }
  }
}

///|
fn encoding_info(
  declared : String?,
  machine : Int?,
  options : Options,
) -> EncodingInfo raise SavError {
  let m = match machine {
    Some(65001) => Some("utf-8")
    Some(1252) => Some("windows-1252")
    Some(936) => Some("gbk")
    Some(54936) => Some("gb18030")
    _ => None
  }
  let (effective, source) = match options.encoding_override {
    Some(s) => (canonical_encoding(s), "override")
    None => {
      let r = match declared {
        Some(s) => Some(canonical_encoding(s))
        None => None
      }
      if r is Some(a) && m is Some(b) && a != b {
        reject(
          "EncodingConflict", "Reliable encoding declarations disagree; confirm encoding and use an explicit override",
        )
      }
      match (r, m) {
        (Some(s), _) => (s, "record20")
        (_, Some(s)) => (s, "machine_code")
        _ => {
          reject(
            "EncodingRequired", "No reliable encoding declaration; confirm source encoding then specify override",
          )
          ("", "")
        }
      }
    }
  }
  let decoder_identity = if options.decoder is Some(_) {
    match options.decoder_identity {
      Some(id) => {
        if id.trim().is_empty() || id.contains("\x00") {
          reject(
            "UnsupportedEncodingVariant", "Custom decoder identity must be nonempty and NUL-free",
          )
        }
        id
      }
      None => {
        reject(
          "UnsupportedEncodingVariant", "A custom decoder must declare its verified identity/version",
        )
        ""
      }
    }
  } else {
    "MoonBit core UTF8 / MoonSav strict UTF8 adapter v1"
  }
  {
    decoder_identity,
    declared,
    machine_code: machine,
    effective,
    selection_source: source,
    profile: effective + "/moonsav-1",
    string_matching_policy: "source-bytes-space-padded-width-v1",
  }
}

///|
pub fn probe_header(input : Bytes) -> Int raise SavError {
  if input.length() < 4 {
    reject("Truncated", "Missing SAV magic", offset=0)
  }
  let magic = input[0:4].to_bytes()
  if magic == b"$FL3" {
    reject("UnsupportedCompression", "FL3/zlib is unsupported", offset=0)
  }
  if magic != b"$FL2" {
    reject("InvalidMagic", "Expected FL2 system file", offset=0)
  }
  if input.length() < 176 {
    reject("Truncated", "Incomplete 176-byte SAV header", offset=input.length())
  }
  let c = Cursor::new(input, pos=64)
  let layout = c.i32()
  if layout == 0x02000000 || layout == 0x03000000 {
    reject("UnsupportedLayout", "Big endian layout is unsupported", offset=64)
  }
  if layout != 2 && layout != 3 {
    reject("UnsupportedLayout", "Unknown SAV layout", offset=64)
  }
  layout
}
