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

    pub fn from_b256(b: b256) -> Bytes {
        // Artificially create bytes with capacity and len
        let mut bytes = Bytes::with_capacity(32);
        bytes.len = 32;
        // Copy bytes from contract_id into the buffer of the target bytes
        __addr_of(b).copy_bytes_to(bytes.buf.ptr, 32);

        bytes
    }

    pub fn from_identity(i: Identity) -> Bytes {
        // Artificially create bytes with capacity and len
        let mut bytes = Bytes::with_capacity(40);
        bytes.len = 40;
        // Copy bytes from contract_id into the buffer of the target bytes
        __addr_of(i).copy_bytes_to(bytes.buf.ptr, 40);
        bytes
    }

    pub fn from_copy_type<T>(value: T) -> Bytes {
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
}

abi MyContract {
    fn hash_u64() -> b256;

    fn hash_bytes_from_u64() -> b256;

    fn hash_bool() -> b256;

    fn hash_bytes_from_bool() -> b256;

    fn hash_identity() -> b256;

    fn hash_bytes_from_identity() -> b256;
}

impl MyContract for Contract {
    fn hash_u64() -> b256 {
        let value: u64 = 10;
        sha256(value)
    }

    fn hash_bytes_from_u64() -> b256 {
        let value: u64 = 10;
        Bytes::from_copy_type(value).sha256()
    }

    fn hash_bool() -> b256 {
        let value = true;
        sha256(value)
    }

    fn hash_bytes_from_bool() -> b256 {
        let value = true;
        Bytes::from_copy_type(value).sha256()
    }

    fn hash_identity() -> b256 {
        let value = Identity::Address(Address {
            value: 0x0000000000000000000000000000000000000000000000000000000000011111,
        });
        sha256(value)
    }

    fn hash_bytes_from_identity() -> b256 {
        let value = Identity::Address(Address {
            value: 0x0000000000000000000000000000000000000000000000000000000000011111,
        });
        Bytes::from_identity(value).sha256()
    }
}
