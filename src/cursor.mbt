///|
struct Cursor {
  bytes : Bytes
  mut pos : Int
}

///|
fn Cursor::new(bytes : Bytes, pos? : Int = 0) -> Cursor {
  { bytes, pos }
}

///|
fn Cursor::take(self : Cursor, n : Int) -> Bytes raise SavError {
  if n < 0 {
    reject("InvalidLength", "Negative length", offset=self.pos)
  }
  if n > self.bytes.length() - self.pos {
    reject("Truncated", "Input ended inside a record", offset=self.pos)
  }
  let out = self.bytes[self.pos:self.pos + n].to_bytes()
  self.pos += n
  out
}

///|
fn Cursor::i32(self : Cursor) -> Int raise SavError {
  let b = self.take(4)
  b[0].to_int() |
  (b[1].to_int() << 8) |
  (b[2].to_int() << 16) |
  (b[3].to_int() << 24)
}

///|
fn Cursor::u64(self : Cursor) -> UInt64 raise SavError {
  let b = self.take(8)
  let mut bits = 0UL
  for i = 0; i < 8; i = i + 1 {
    bits = bits | (b[i].to_uint64() << (i * 8))
  }
  bits
}

///|
fn Cursor::f64(self : Cursor) -> Double raise SavError {
  self.u64().reinterpret_as_double()
}

///|
fn bits_bytes(bits : UInt64) -> Bytes {
  Bytes::makei(8, i => ((bits >> (i * 8)) & 255UL).to_byte())
}

///|
fn hex_bits(bits : UInt64) -> String {
  let s = bits.to_string(radix=16)
  String::make(16 - s.length(), '0') + s
}

///|
fn raw_bits(bytes : Bytes) -> UInt64 raise SavError {
  Cursor::new(bytes).u64()
}

///|
fn finite(value : Double) -> Bool {
  value == value &&
  value <= 1.7976931348623157e308 &&
  value >= -1.7976931348623157e308
}

///|
fn decimal(bits : UInt64) -> String {
  if bits == 0x8000000000000000UL {
    "-0"
  } else {
    bits.reinterpret_as_double().to_string()
  }
}

///|
fn ascii(bytes : Bytes) -> String raise SavError {
  for b in bytes {
    if b.to_int() > 127 {
      reject("InvalidDictionary", "Expected ASCII control metadata")
    }
  }
  @utf8.decode(bytes[:], ignore_bom=true) catch {
    _ => {
      reject("InvalidDictionary", "Invalid ASCII")
      ""
    }
  }
}
