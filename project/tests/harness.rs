use fuels::{
    core::abi_encoder::ABIEncoder,
    prelude::*,
    signers::fuel_crypto::Hasher,
    tx::{Address, ContractId},
    types::{traits::Tokenizable, Bits256, Identity},
};

const DEFAULT_TEST_B256: &str =
    "0x0000000000000000000000000000000000000000000000000000000000011111";

// Load abi from json
abigen!(Contract(
    name = "MyContract",
    abi = "out/debug/project-abi.json"
));

async fn get_contract_instance() -> (MyContract, ContractId) {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await;
    let wallet = wallets.pop().unwrap();

    let id = Contract::deploy(
        "./out/debug/project.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "./out/debug/project-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();

    let instance = MyContract::new(id.clone(), wallet);

    (instance, id.into())
}

#[tokio::test]
async fn hashing_u64() {
    let (instance, _id) = get_contract_instance().await;

    let hash_u64_response = instance.methods().hash_u64().call().await.unwrap();

    let value: u64 = 10;
    let value = value.to_be_bytes();
    let rust_hash = Hasher::hash(value);

    let hash_bytes_from_u64_response = instance
        .methods()
        .hash_bytes_from_u64()
        .call()
        .await
        .unwrap();

    assert_eq!(hash_u64_response.value, Bits256(rust_hash.into()));
    assert_eq!(
        hash_bytes_from_u64_response.value,
        Bits256(rust_hash.into())
    );
}

#[tokio::test]
async fn hashing_bool() {
    let (instance, _id) = get_contract_instance().await;

    let hash_bool_response = instance.methods().hash_bool().call().await.unwrap();

    let value = true as u64;
    let value = value.to_be_bytes();
    let rust_hash = Hasher::hash(value);

    let hash_bytes_from_bool_response = instance
        .methods()
        .hash_bytes_from_bool()
        .call()
        .await
        .unwrap();

    assert_eq!(hash_bool_response.value, Bits256(rust_hash.into()));
    assert_eq!(
        hash_bytes_from_bool_response.value,
        Bits256(rust_hash.into())
    );
}

#[tokio::test]
async fn hashing_identity() {
    let (instance, _id) = get_contract_instance().await;

    let hash_identity_response = instance.methods().hash_identity().call().await.unwrap();

    let value = Identity::Address(Address::new(
        Bits256::from_hex_str(DEFAULT_TEST_B256).unwrap().0,
    ));
    let value_token = value.into_token();
    let encoded_value_token = ABIEncoder::encode(&vec![value_token]).unwrap().resolve(0);
    let rust_hash = Hasher::hash(encoded_value_token);

    let hash_bytes_from_identity_response = instance
        .methods()
        .hash_bytes_from_identity()
        .call()
        .await
        .unwrap();

    assert_eq!(hash_identity_response.value, Bits256(rust_hash.into()));
    assert_eq!(
        hash_bytes_from_identity_response.value,
        Bits256(rust_hash.into())
    );
}

/*
#[tokio::test]
async fn hashing_type1() {
    let (instance, _id) = get_contract_instance().await;

    let hash_type1_response = instance.methods().hash_type1().call().await.unwrap();

    let value = Type1 {
        boolean: true,
        number: 12345,
        identity: Identity::Address(Address::new(
            Bits256::from_hex_str(
                DEFAULT_TEST_B256,
            )
            .unwrap()
            .0,
        )),
    };
    let value_token = value.into_token();
    let encoded_value_token = ABIEncoder::encode(&vec![value_token]).unwrap().resolve(0);
    let rust_hash = Hasher::hash(encoded_value_token);

    let hash_bytes_from_type1_response = instance
        .methods()
        .hash_bytes_from_type1()
        .call()
        .await
        .unwrap();

    // println!("hash_type1_response \n{:?}", hash_type1_response.value.0);
    // println!("rust_hash \n{:?}", Bits256(rust_hash.into()).0);
    // println!(
    //     "hash_bytes_from_type1_response \n{:?}",
    //     hash_bytes_from_type1_response.value.0
    // );

    assert_eq!(hash_type1_response.value, Bits256(rust_hash.into()));
    assert_eq!(
        hash_bytes_from_type1_response.value,
        Bits256(rust_hash.into())
    );
}

#[tokio::test]
async fn test_from_trait() {
    let (instance, _id) = get_contract_instance().await;

    let test_from_trait_response = instance.methods().test_from_trait().call().await.unwrap();

    assert_eq!(test_from_trait_response.value, true);
}
*/

#[tokio::test]
async fn hashing_type2() {
    let (instance, _id) = get_contract_instance().await;

    let hash_bytes_from_type2_response = instance
        .methods()
        .hash_bytes_from_type2()
        .call()
        .await
        .unwrap();

    let mut encoded_boolean = (true as u64).to_be_bytes().to_vec();
    let mut encoded_number = 12345u64.to_be_bytes().to_vec();

    let identity_token = Identity::Address(Address::new(
        Bits256::from_hex_str(DEFAULT_TEST_B256).unwrap().0,
    ))
    .into_token();
    let mut encoded_identity = ABIEncoder::encode(&vec![identity_token])
        .unwrap()
        .resolve(0);

    let mut bytes = 6789u64.to_be_bytes().to_vec();

    encoded_boolean.append(&mut encoded_number);
    encoded_boolean.append(&mut encoded_identity);
    encoded_boolean.append(&mut bytes);

    let rust_hash = Hasher::hash(encoded_boolean);

    assert_eq!(
        hash_bytes_from_type2_response.value,
        Bits256(rust_hash.into())
    );
}

#[tokio::test]
async fn hashing_option() {
    let (instance, _id) = get_contract_instance().await;

    let hash_option_some_response = instance.methods().hash_option_some().call().await.unwrap();
    let hash_option_none_response = instance.methods().hash_option_none().call().await.unwrap();

    let some1_token = Option::Some(12345u64).into_token();
    let encoded_some1 = ABIEncoder::encode(&vec![some1_token]).unwrap().resolve(0);
    let some1_hash = Hasher::hash(encoded_some1);

    let some2_token = Option::Some(Identity::Address(Address::new(
        Bits256::from_hex_str(DEFAULT_TEST_B256).unwrap().0,
    )))
    .into_token();
    let encoded_some2 = ABIEncoder::encode(&vec![some2_token]).unwrap().resolve(0);
    let some2_hash = Hasher::hash(encoded_some2);

    let rust_some_hashes = (Bits256(some1_hash.into()), Bits256(some2_hash.into()));

    let none1: Option<u64> = Option::None;
    let encoded_none1 = ABIEncoder::encode(&vec![none1.into_token()])
        .unwrap()
        .resolve(0);
    let none1_hash = Hasher::hash(encoded_none1);

    let none2: Option<Identity> = Option::None;
    let encoded_none2 = ABIEncoder::encode(&vec![none2.into_token()])
        .unwrap()
        .resolve(0);
    let none2_hash = Hasher::hash(encoded_none2);

    let rust_none_hashes = (Bits256(none1_hash.into()), Bits256(none2_hash.into()));

    let hash_bytes_from_option_some_response = instance
        .methods()
        .hash_bytes_from_option_some()
        .call()
        .await
        .unwrap();
    let hash_bytes_from_option_none_response = instance
        .methods()
        .hash_bytes_from_option_none()
        .call()
        .await
        .unwrap();

    assert_eq!(hash_option_some_response.value, rust_some_hashes);
    assert_eq!(rust_some_hashes, hash_bytes_from_option_some_response.value);

    assert_eq!(hash_option_none_response.value, rust_none_hashes);
    assert_eq!(rust_none_hashes, hash_bytes_from_option_none_response.value);
}
