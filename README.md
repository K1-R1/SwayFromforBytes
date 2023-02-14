# SwayFromforBytes

- Implement `From<> for Bytes` methods for `u64` and `bool`
- Confirm equivalence between: Rust hashing, Sway hashing, Sway hashing via Bytes for:

1. u64 ✅
2. bool ✅
3. Identity ✅

- Declare and implement `into_bytes` trait
- Confirm equivalence between: Rust hashing, Sway hashing, Sway hashing via Bytes for:

1. struct with fields of the above types✅
2. struct with fields of the above types + Bytes✅
3. struct from point 2. but all fields optional
