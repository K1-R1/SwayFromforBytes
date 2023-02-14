contract;

use std::{alloc::realloc_bytes, bytes::Bytes, hash::sha256};

impl Bytes {
    pub fn sha256(self) -> b256 { // not in this forc version
        let mut result_buffer = b256::min();
        asm(hash: result_buffer, ptr: self.buf.ptr, bytes: self.len) {
            s256 hash ptr bytes;
            hash: b256
        }
    }

    pub fn append(ref mut self, ref other: self) { // not in this forc version
        if other.len == 0 {
            return
        };

        // optimization for when starting with empty bytes and appending to it
        if self.len == 0 {
            self = other;
            other.clear();
            return;
        };

        let both_len = self.len + other.len;
        let other_start = self.len;

        // reallocate with combined capacity, write `other`, set buffer capacity
        self.buf.ptr = realloc_bytes(self.buf.ptr(), self.buf.capacity(), both_len);

        let mut i = 0;
        while i < other.len {
            let new_ptr = self.buf.ptr().add_uint_offset(other_start);
            new_ptr.add_uint_offset(i).write_byte(other.buf.ptr.add_uint_offset(i).read_byte());
            i += 1;
        }

        // set capacity and length
        self.buf.cap = both_len;
        self.len = both_len;

        // clear `other`
        other.clear();
    }

    pub fn from_b256(b: b256) -> Bytes { // not in this forc version
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

struct Type1 {
    boolean: bool,
    number: u64,
    identity: Identity,
}

impl From<Type1> for Bytes {
    fn from(t: Type1) -> Bytes {
        let mut bytes = Bytes::new();
        bytes.append(Bytes::from_copy_type(t.boolean));
        bytes.append(Bytes::from_copy_type(t.number));
        bytes.append(Bytes::from_identity(t.identity));
        bytes
    }

    fn into(self) -> Type1 { // Needed by the `From` trait. Could be lossy!
        let mut value = Type1 {
            boolean: false,
            number: 0,
            identity: Identity::Address(Address::from(0x0000000000000000000000000000000000000000000000000000000000000000)),
        };
        let ptr = __addr_of(value);
        self.buf.ptr().copy_to::<Type1>(ptr, 1);

        value
    }
}

abi MyContract {
    fn hash_u64() -> b256;

    fn hash_bytes_from_u64() -> b256;

    fn hash_bool() -> b256;

    fn hash_bytes_from_bool() -> b256;

    fn hash_identity() -> b256;

    fn hash_bytes_from_identity() -> b256;

    fn hash_type1() -> b256;

    fn hash_bytes_from_type1() -> b256;

    fn expose_type1() -> Type1;

    fn test_from_trait() -> bool;
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

    fn hash_type1() -> b256 {
        let value = Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(0x0000000000000000000000000000000000000000000000000000000000011111)),
        };
        sha256(value)
    }

    fn hash_bytes_from_type1() -> b256 {
        let value = Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(0x0000000000000000000000000000000000000000000000000000000000011111)),
        };
        Bytes::from(value).sha256()
    }

    fn expose_type1() -> Type1 {
        Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(0x0000000000000000000000000000000000000000000000000000000000011111)),
        }
    }

    fn test_from_trait() -> bool {
        let t1 = Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(0x0000000000000000000000000000000000000000000000000000000000011111)),
        };
        let bytes = Bytes::from(t1);
        let t2: Type1 = bytes.into();
        if t1.boolean == t2.boolean
            && t1.number == t2.number
            && t1.identity == t2.identity
        {
            true
        } else {
            false
        }
    }
}
