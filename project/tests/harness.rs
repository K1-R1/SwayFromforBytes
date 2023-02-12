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
async fn can_get_contract_id() {
    let (_instance, _id) = get_contract_instance().await;
}

#[tokio::test]
async fn hashing_u64() {
    let (instance, _id) = get_contract_instance().await;

    let response = instance.methods().hash_u64().call().await.unwrap();

    let value: u64 = 10;
    let value = value.to_be_bytes();
    let rust_hash = Hasher::hash(value);

    dbg!(response.value.0);
    dbg!(Bits256(rust_hash.into()).0);

    assert_eq!(response.value, Bits256(rust_hash.into()));
}
