# SwayFromforBytes

Using forc 0.33.1

- Implement `From<> for Bytes` methods for `u64`, `bool`, `Identity`, custom types, and custom types with `Option` fields.
- Confirm equivalence between: Rust hashing, Sway hashing, Sway hashing via Bytes for:

1. u64 ✅
2. bool ✅
3. Identity ✅
4. Option✅

- Implement `From<>` traits / equivalents
- Confirm equivalence between: Rust hashing, Sway hashing, Sway hashing via Bytes for:

1. struct with fields of the above types✅
2. struct with fields of the above types + Bytes✅
3. struct from point 2. but all fields optional
