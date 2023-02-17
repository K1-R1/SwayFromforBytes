contract;

use std::{alloc::realloc_bytes, bytes::Bytes, constants::ZERO_B256, hash::sha256};

const DEFAULT_TEST_B256 = 0x0000000000000000000000000000000000000000000000000000000000011111;

impl Bytes {
    ////////////////////////////////////// not in this forc version //////////////////////////////////////////////////////
    pub fn sha256(self) -> b256 {
        let mut result_buffer = b256::min();
        asm(hash: result_buffer, ptr: self.buf.ptr, bytes: self.len) {
            s256 hash ptr bytes;
            hash: b256
        }
    }

    pub fn append(ref mut self, ref other: self) {
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
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

    pub fn from_reference_type<T>(t: T) -> Bytes { // NOTE: Does not work correctly for Bytes from Option::Some(Bytes)
        // Artificially create bytes with capacity and len
        let size = __size_of::<T>();
        let mut bytes = Bytes::with_capacity(size);
        bytes.len = size;
        // Copy bytes from contract_id into the buffer of the target bytes
        __addr_of(t).copy_bytes_to(bytes.buf.ptr, size);
        bytes
    }

    pub fn from_identity(i: Identity) -> Bytes { // More gas efficient form of `from_reference_type`, as `size` can be hardcoded.
        // Artificially create bytes with capacity and len
        let mut bytes = Bytes::with_capacity(40);
        bytes.len = 40;
        // Copy bytes from contract_id into the buffer of the target bytes
        __addr_of(i).copy_bytes_to(bytes.buf.ptr, 40);
        bytes
    }
}




/* Commented out all Type 1 related code, as having multiple `impl From<> for Bytes` blocks currently causes error. This code has passed it's tests.
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
            identity: Identity::Address(Address::from(ZERO_B256)),
        };
        let ptr = __addr_of(value);
        self.buf.ptr().copy_to::<Type1>(ptr, 1);

        value
    }
}
*/
struct Type2 {
    boolean: bool,
    number: u64,
    identity: Identity,
    bytes: Bytes,
}

impl From<Type2> for Bytes {
    fn from(t: Type2) -> Bytes {
        let mut bytes = Bytes::new();
        bytes.append(Bytes::from_copy_type(t.boolean));
        bytes.append(Bytes::from_copy_type(t.number));
        bytes.append(Bytes::from_identity(t.identity));
        bytes.append(t.bytes);
        bytes
    }

    fn into(self) -> Type2 { // Needed by the `From` trait. Could be lossy!
        let mut value = Type2 {
            boolean: false,
            number: 0,
            identity: Identity::Address(Address::from(ZERO_B256)),
            bytes: Bytes::from_copy_type(0),
        };
        let ptr = __addr_of(value);
        self.buf.ptr().copy_to::<Type2>(ptr, 1);

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




    /*
    fn hash_type1() -> b256;

    fn hash_bytes_from_type1() -> b256;

    fn expose_type1() -> Type1;

    fn test_from_trait() -> bool;
    */
    fn hash_bytes_from_type2() -> b256;

    fn test_from_type2_trait() -> bool;

    fn hash_option_some() -> (b256, b256);

    fn hash_option_none() -> (b256, b256);

    fn hash_bytes_from_option_some() -> (b256, b256);

    fn hash_bytes_from_option_none() -> (b256, b256);

    fn hash_bytes_from_option_some_bytes() -> b256;
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
            value: DEFAULT_TEST_B256,
        });
        sha256(value)
    }

    fn hash_bytes_from_identity() -> b256 {
        let value = Identity::Address(Address {
            value: DEFAULT_TEST_B256,
        });
        Bytes::from_reference_type(value).sha256()
    }




    /*
    fn hash_type1() -> b256 {
        let value = Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(DEFAULT_TEST_B256)),
        };
        sha256(value)
    }

    fn hash_bytes_from_type1() -> b256 {
        let value = Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(DEFAULT_TEST_B256)),
        };
        Bytes::from(value).sha256()
    }

    fn expose_type1() -> Type1 {
        Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(DEFAULT_TEST_B256)),
        }
    }

    fn test_from_trait() -> bool {
        let t1 = Type1 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(DEFAULT_TEST_B256)),
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
    */
    fn hash_bytes_from_type2() -> b256 {
        let value = Type2 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(DEFAULT_TEST_B256)),
            bytes: Bytes::from_copy_type(6789),
        };
        Bytes::from(value).sha256()
    }

    fn test_from_type2_trait() -> bool {
        let t1 = Type2 {
            boolean: true,
            number: 12345,
            identity: Identity::Address(Address::from(DEFAULT_TEST_B256)),
            bytes: Bytes::from_copy_type(6789),
        };
        let bytes = Bytes::from(t1);
        let t2: Type2 = bytes.into();
        if t1.boolean == t2.boolean
            && t1.number == t2.number
            && t1.identity == t2.identity
            && t1.bytes == t2.bytes
        {
            true
        } else {
            false
        }
    }

    fn hash_option_some() -> (b256, b256) {
        let value1 = Option::Some(12345);
        let value2 = Option::Some(Identity::Address(Address::from(DEFAULT_TEST_B256)));
        (sha256(value1), sha256(value2))
    }

    fn hash_option_none() -> (b256, b256) {
        let value1: Option<u64> = Option::None;
        let value2: Option<Identity> = Option::None;
        (sha256(value1), sha256(value2))
    }

    fn hash_bytes_from_option_some() -> (b256, b256) {
        let value1 = Option::Some(12345);
        let value2 = Option::Some(Identity::Address(Address::from(DEFAULT_TEST_B256)));
        (
            Bytes::from_reference_type(value1).sha256(),
            Bytes::from_reference_type(value2).sha256(),
        )
    }

    fn hash_bytes_from_option_none() -> (b256, b256) {
        let value1: Option<u64> = Option::None;
        let value2: Option<Identity> = Option::None;
        (
            Bytes::from_reference_type(value1).sha256(),
            Bytes::from_reference_type(value2).sha256(),
        )
    }

    fn hash_bytes_from_option_some_bytes() -> b256 {
        let value = Option::Some(Bytes::from_reference_type(Identity::Address(Address::from(DEFAULT_TEST_B256))));
        option_bytes_to_bytes(value).sha256()
    }
}

fn option_bytes_to_bytes(o: Option<Bytes>) -> Bytes {
    let size = __size_of::<Option<Bytes>>();
    match o {
        Option::None => {
            let mut option_bytes = Bytes::from_copy_type(0u64);
            option_bytes.append(Bytes::with_capacity(size - 8));
            option_bytes
        },
        Option::Some(bytes) => {
            let mut option_bytes = Bytes::from_copy_type(1u64);
            option_bytes.append(bytes);
            option_bytes
        }
    }
}
