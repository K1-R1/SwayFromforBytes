contract;

use std::hash::sha256;

abi MyContract {
    fn hash_u64() -> b256;
}

impl MyContract for Contract {
    fn hash_u64() -> b256 {
        let value: u64 = 10;
        sha256(value)
    }
}
