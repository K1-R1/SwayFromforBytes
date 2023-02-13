contract;

use std::{bytes::Bytes, hash::sha256};

impl Bytes {
    pub fn sha256(self) -> b256 {
        let mut result_buffer = b256::min();
        asm(hash: result_buffer, ptr: self.buf.ptr, bytes: self.len) {
            s256 hash ptr bytes;
            hash: b256
        }
    }
}

abi MyContract {
    fn hash_u64() -> b256;

    fn hash_bytes_from_u64() -> b256;

    fn hash_bool() -> b256;

    fn hash_bytes_from_bool() -> b256;
}

impl MyContract for Contract {
    fn hash_u64() -> b256 {
        let value: u64 = 10;
        sha256(value)
    }

    fn hash_bytes_from_u64() -> b256 {
        let value: u64 = 10;
        from_copy_type_for_bytes(value).sha256()
    }

    fn hash_bool() -> b256 {
        let value = true;
        sha256(value)
    }

    fn hash_bytes_from_bool() -> b256 {
        let value = true;
        from_copy_type_for_bytes(value).sha256()
    }
}

fn from_copy_type_for_bytes<T>(value: T) -> Bytes {
    // Artificially create bytes with capacity and len
    let mut bytes = Bytes::with_capacity(8);
    bytes.len = 8;

    asm(buffer, ptr: value, dst: bytes.buf.ptr, len: 8) {
        move buffer sp; // Make `buffer` point to the current top of the stack
        cfei i8; // Grow stack by 1 word
        sw buffer ptr i0; // Save value in register at `ptr` to memory at `buffer`
        mcp dst buffer len; // Copy `len` bytes in memory starting from `buffer`, to `dst`
        cfsi i8; // Shrink stack by 1 word
    }

    bytes
}
