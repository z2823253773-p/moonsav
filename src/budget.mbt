///|
priv struct DictionaryBudget {
  limits : Limits
  mut raw_bytes : Int
  mut decoded_bytes : Int
  mut label_entries : Int
}

///|
fn DictionaryBudget::new(limits : Limits) -> DictionaryBudget {
  { limits, raw_bytes: 0, decoded_bytes: 0, label_entries: 0 }
}

///|
fn DictionaryBudget::observe_raw(
  self : DictionaryBudget,
  n : Int,
) -> Unit raise SavError {
  limit(n, self.limits.dictionary_bytes, "dictionary_bytes")
  self.raw_bytes = n
}

///|
fn DictionaryBudget::raw(
  self : DictionaryBudget,
  n : Int,
) -> Unit raise SavError {
  if n < 0 || n > self.limits.dictionary_bytes - self.raw_bytes {
    reject("ResourceLimit", "Raw dictionary payload budget exceeded")
  }
  self.raw_bytes += n
}

///|
fn DictionaryBudget::decoded(
  self : DictionaryBudget,
  text : String,
) -> Unit raise SavError {
  if text.length() > (self.limits.dictionary_bytes - self.decoded_bytes) / 2 {
    reject("ResourceLimit", "Decoded dictionary budget exceeded")
  }
  self.decoded_bytes += text.length() * 2
}

///|
fn DictionaryBudget::labels(
  self : DictionaryBudget,
  n : Int,
  associations? : Int = 1,
) -> Unit raise SavError {
  if n < 0 ||
    associations <= 0 ||
    n >
    (self.limits.dictionary_bytes / 4096 - self.label_entries) / associations {
    reject("ResourceLimit", "Dictionary label entry bookkeeping exceeds budget")
  }
  self.label_entries += n * associations
}

///|
fn DictionaryBudget::text(
  self : DictionaryBudget,
  text : String,
) -> Unit raise SavError {
  self.decoded(text)
  // UTF-8 source-like payload accounting for JSON-only dictionary strings.
  if text.length() > self.limits.dictionary_bytes - self.raw_bytes {
    reject("ResourceLimit", "Raw dictionary text budget exceeded")
  }
  self.raw(text.to_bytes().length())
}
