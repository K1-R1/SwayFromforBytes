# SwayFromforBytes

Using forc 0.33.1

- Implement `From<> for Bytes` methods for `u64`, `bool`, `Identity`, custom types, and custom types with `Option` fields.
- Confirm equivalence between: Rust hashing, Sway hashing, Sway hashing via Bytes for:

- [x] u64 
- [x] bool 
- [x] Identity 
- [x] Option

- Implement `From<>` traits / equivalents
- Confirm equivalence between: Rust hashing, Sway hashing, Sway hashing via Bytes for:

- [x] struct with fields of the above types
- [x] struct with fields of the above types + Bytes
- [x] Option< Bytes >
