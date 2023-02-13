use fuels::{prelude::*, signers::fuel_crypto::Hasher, tx::ContractId, types::Bits256};

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

    println!("hash_u64_response: \n{:?}", hash_u64_response.value.0);
    println!("rust_hash: \n{:?}", Bits256(rust_hash.into()).0);
    println!(
        "hash_bytes_from_u64_response: \n{:?}",
        hash_bytes_from_u64_response.value.0
    );

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

    println!("hash_bool_response: \n{:?}", hash_bool_response.value.0);
    println!("rust_hash: \n{:?}", Bits256(rust_hash.into()).0);
    println!(
        "hash_bytes_from_bool_response: \n{:?}",
        hash_bytes_from_bool_response.value.0
    );

    assert_eq!(hash_bool_response.value, Bits256(rust_hash.into()));
    assert_eq!(
        hash_bytes_from_bool_response.value,
        Bits256(rust_hash.into())
    );
}
