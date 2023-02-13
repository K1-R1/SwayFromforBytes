use fuels::{
    core::abi_encoder::ABIEncoder,
    prelude::*,
    signers::fuel_crypto::Hasher,
    tx::{Address, ContractId},
    types::{traits::Tokenizable, Bits256, Identity},
};

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

    // println!("hash_u64_response: \n{:?}", hash_u64_response.value.0);
    // println!("rust_hash: \n{:?}", Bits256(rust_hash.into()).0);
    // println!(
    //     "hash_bytes_from_u64_response: \n{:?}",
    //     hash_bytes_from_u64_response.value.0
    // );

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

    // println!("hash_bool_response: \n{:?}", hash_bool_response.value.0);
    // println!("rust_hash: \n{:?}", Bits256(rust_hash.into()).0);
    // println!(
    //     "hash_bytes_from_bool_response: \n{:?}",
    //     hash_bytes_from_bool_response.value.0
    // );

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
        Bits256::from_hex_str("0x0000000000000000000000000000000000000000000000000000000000011111")
            .unwrap()
            .0,
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

    println!(
        "hash_identity_response: \n{:?}",
        hash_identity_response.value.0
    );
    println!("rust_hash: \n{:?}", Bits256(rust_hash.into()).0);
    println!(
        "hash_bytes_from_identity_response: \n{:?}",
        hash_bytes_from_identity_response.value.0
    );

    let value_2 =
        Bits256::from_hex_str("0x0000000000000000000000000000000000000000000000000000000000011111")
            .unwrap()
            .0;
    let value_2_hash = Hasher::hash(value_2);
    println!("value_2_hash: \n{:?}", Bits256(value_2_hash.into()).0);

    assert_eq!(hash_identity_response.value, Bits256(rust_hash.into()));
    assert_eq!(
        hash_bytes_from_identity_response.value,
        Bits256(rust_hash.into())
    );
}
