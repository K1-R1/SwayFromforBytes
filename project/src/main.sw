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
        let mut bytes = Bytes::with_capacity(32);
        bytes.len = 32;
        // Copy bytes from contract_id into the buffer of the target bytes
        __addr_of(i).copy_bytes_to(bytes.buf.ptr, 32);
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

// impl Bytes {
//     pub fn from_identity(i: Identity) -> Bytes {
//         match i {
//             Identity::Address(address) => Bytes::from_b256(address.value),
//             Identity::ContractId(contract_identifier) => Bytes::from_b256(contract_identifier.value),
//         }
//     }
// }
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

/*
Check: if b256 is the value, then sha256(b256) == sha256(Address::from(b256)) == sha256(Identity::Address(Address::from(b256)))
- Sway
- rust SDK
    - Check that hashing b256 in the way that value_2 does, is the same as via b256 Token
*/
abi info {
    fn test_sway_1() -> b256;

    fn test_sway_2() -> b256;

    fn test_sway_3() -> b256;

    fn test_sway_4() -> bool;
}

impl info for Contract {
    fn test_sway_1() -> b256 {
        let value = 0x0000000000000000000000000000000000000000000000000000000000011111;
        sha256(value)
    }

    fn test_sway_2() -> b256 {
        let value = 0x0000000000000000000000000000000000000000000000000000000000011111;
        sha256(Address::from(value))
    }

    fn test_sway_3() -> b256 {
        let value = 0x0000000000000000000000000000000000000000000000000000000000011111;
        sha256(Identity::Address(Address::from(value)))
    }

    fn test_sway_4() -> bool {
        let value = 0x0000000000000000000000000000000000000000000000000000000000011111;
        let a = sha256(value);
        let b = sha256(Address::from(value));
        let c = sha256(Identity::Address(Address::from(value)));
        require(a == b, "a != b");
        require(b == c, "b != c");
        true
    }
}
