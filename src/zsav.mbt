///| ZSAV containers are parsed here. The inflater is only an RFC1950 primitive.
priv struct ZsavBlock {
  offset : Int
  compressed : Int
  inflated : Int
}

///|
priv struct ZsavReader {
  input : Bytes
  blocks : Array[ZsavBlock]
  inflate : (Bytes, Int) -> Bytes raise SavError
  mut index : Int
  mut block : Bytes
  mut within : Int
  mut pos : Int
}

///| Convert only after a wide bounds check; malicious offsets must not wrap Int.
fn zsav_offset(c : Cursor, maximum : Int) -> Int raise SavError {
  let offset = c.pos
  let n = c.u64()
  if n > maximum.to_uint64() {
    reject("InvalidCompression", "ZSAV offset or length outside input", offset~)
  }
  n.to_int()
}

///|
fn ZsavReader::new(input : Bytes, d : Dictionary) -> ZsavReader raise SavError {
  let c = Cursor::new(input, pos=d.data_offset)
  let base = zsav_offset(c, input.length())
  let trailer = zsav_offset(c, input.length())
  let length = zsav_offset(c, input.length())
  if base != d.data_offset || trailer < c.pos ||
    length < 24 || (length - 24) % 24 != 0 ||
    length != input.length() - trailer {
    reject("InvalidCompression", "Inconsistent ZSAV header/trailer", offset=d.data_offset)
  }
  let count = (length - 24) / 24
  // Budget the directory before allocating its descriptors.
  limit(length, d.options.limits.dictionary_bytes, "ZSAV directory bytes")
  limit(count, 65536, "ZSAV blocks")
  let t = Cursor::new(input, pos=trailer)
  let int_bias = t.u64().reinterpret_as_int64()
  let zero = t.u64()
  let size = t.i32()
  let declared_count = t.i32()
  if int_bias.to_double() != -d.bias || zero != 0UL || size <= 0 ||
    declared_count != count {
    reject("InvalidCompression", "Invalid ZSAV trailer fields", offset=trailer)
  }
  let blocks = []
  let mut compressed_offset = c.pos
  let mut total = 0
  for i = 0; i < count; i = i + 1 {
    let record_offset = t.pos
    let logical_offset = t.u64()
    let offset = zsav_offset(t, trailer)
    let inflated = t.i32()
    let compressed = t.i32()
    if logical_offset != base.to_uint64() + total.to_uint64() ||
      offset != compressed_offset || compressed <= 0 ||
      compressed > trailer - offset || inflated < 0 ||
      inflated > size || (i < count - 1 && inflated != size) {
      reject("InvalidCompression", "Invalid ZSAV block descriptor", offset=record_offset)
    }
    limit(compressed, 16777216, "ZSAV compressed block bytes")
    limit(inflated, 16777216, "ZSAV inflated block bytes")
    if inflated > d.options.limits.inflated_bytes - total {
      reject("ResourceLimit", "ZSAV inflated_bytes exceeds limit", offset=record_offset)
    }
    total += inflated
    compressed_offset += compressed
    blocks.push({ offset, compressed, inflated })
  }
  if compressed_offset != trailer {
    reject("InvalidCompression", "ZSAV blocks do not end at trailer", offset=trailer)
  }
  let inflate = match d.options.inflater {
    Some(f) => f
    None => {
      reject("UnsupportedCompression", "ZSAV data requires a bounded RFC1950 inflater adapter")
      fn(_, _) { b"" }
    }
  }
  { input, blocks, inflate, index: 0, block: b"", within: 0, pos: base }
}

///| Loads at most one block. Checks even empty blocks and exact inflated size.
fn ZsavReader::at_end(self : ZsavReader) -> Bool raise SavError {
  while self.within == self.block.length() && self.index < self.blocks.length() {
    let b = self.blocks[self.index]
    let data = (self.inflate)(self.input[b.offset:b.offset + b.compressed].to_bytes(), b.inflated) catch {
      SavFailure(e) => raise SavFailure({ ..e, byte_offset: Some(b.offset) })
    }
    if data.length() != b.inflated {
      reject("InvalidCompression", "Inflated ZSAV size disagrees with directory", offset=b.offset)
    }
    self.block = data
    self.within = 0
    self.index += 1
  }
  self.within == self.block.length()
}

///|
fn ZsavReader::take(self : ZsavReader, n : Int) -> Bytes raise SavError {
  let out : Array[Byte] = Array::make(n, b'\x00')
  let mut written = 0
  while written < n {
    if self.at_end() {
      reject("Truncated", "ZSAV bytecode ended inside an element", offset=self.pos)
    }
    let available = self.block.length() - self.within
    let amount = if available < n - written { available } else { n - written }
    for i = 0; i < amount; i = i + 1 {
      out[written + i] = self.block[self.within + i]
    }
    written += amount
    self.within += amount
    self.pos += amount
  }
  Bytes::makei(n, i => out[i])
}
