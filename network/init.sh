#!/bin/bash

ADMIN_ADDRESS=neutron14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s5c2epq
NEUTROND_BINARY=neutrond
GAIAD_BINARY=gaiad
CHAIN_DIR=./data
CHAINID_1=test-1
CHAINID_2=test-2
DAO_CONTRACT=./contracts/neutron_dao.wasm
VAL_MNEMONIC_1="clock post desk civil pottery foster expand merit dash seminar song memory figure uniform spice circle try happy obvious trash crime hybrid hood cushion"
VAL_MNEMONIC_2="angry twist harsh drastic left brass behave host shove marriage fall update business leg direct reward object ugly security warm tuna model broccoli choice"
DEMO_MNEMONIC_1="banner spread envelope side kite person disagree path silver will brother under couch edit food venture squirrel civil budget number acquire point work mass"
DEMO_MNEMONIC_2="veteran try aware erosion drink dance decade comic dawn museum release episode original list ability owner size tuition surface ceiling depth seminar capable only"
DEMO_MNEMONIC_3="obscure canal because tomorrow tribe sibling describe satoshi kiwi upgrade bless empty math trend erosion oblige donate label birth chronic hazard ensure wreck shine"
RLY_MNEMONIC_1="alley afraid soup fall idea toss can goose become valve initial strong forward bright dish figure check leopard decide warfare hub unusual join cart"
RLY_MNEMONIC_2="record gift you once hip style during joke field prize dust unique length more pencil transfer quit train device arrive energy sort steak upset"
P2PPORT_1=16656
P2PPORT_2=26656
RPCPORT_1=16657
RPCPORT_2=26657
RESTPORT_1=1316
RESTPORT_2=1317
ROSETTA_1=8080
ROSETTA_2=8081

# Stop if it is already running
if pgrep -x "$NEUTROND_BINARY" >/dev/null; then
    echo "Terminating $NEUTROND_BINARY..."
    killall $NEUTROND_BINARY
fi

# Stop if it is already running
if pgrep -x "$GAIAD_BINARY" >/dev/null; then
    echo "Terminating $GAIAD_BINARY..."
    killall $GAIAD_BINARY
fi

echo "Removing previous data..."
rm -rf $CHAIN_DIR/$CHAINID_1 &> /dev/null
rm -rf $CHAIN_DIR/$CHAINID_2 &> /dev/null

# Add directories for both chains, exit if an error occurs
if ! mkdir -p $CHAIN_DIR/$CHAINID_1 2>/dev/null; then
    echo "Failed to create chain folder. Aborting..."
    exit 1
fi

if ! mkdir -p $CHAIN_DIR/$CHAINID_2 2>/dev/null; then
    echo "Failed to create chain folder. Aborting..."
    exit 1
fi

echo "Initializing $CHAINID_1..."
echo "Initializing $CHAINID_2..."
$NEUTROND_BINARY init test --home $CHAIN_DIR/$CHAINID_1 --chain-id=$CHAINID_1
$GAIAD_BINARY init test --home $CHAIN_DIR/$CHAINID_2 --chain-id=$CHAINID_2

echo "Adding genesis accounts..."
echo $VAL_MNEMONIC_1 | $NEUTROND_BINARY keys add val1 --home $CHAIN_DIR/$CHAINID_1 --recover --keyring-backend=test
echo $VAL_MNEMONIC_2 | $GAIAD_BINARY keys add val2 --home $CHAIN_DIR/$CHAINID_2 --recover --keyring-backend=test
echo $DEMO_MNEMONIC_1 | $NEUTROND_BINARY keys add demowallet1 --home $CHAIN_DIR/$CHAINID_1 --recover --keyring-backend=test
echo $DEMO_MNEMONIC_2 | $GAIAD_BINARY keys add demowallet2 --home $CHAIN_DIR/$CHAINID_2 --recover --keyring-backend=test
echo $DEMO_MNEMONIC_3 | $NEUTROND_BINARY keys add demowallet3 --home $CHAIN_DIR/$CHAINID_1 --recover --keyring-backend=test
echo $RLY_MNEMONIC_1 | $NEUTROND_BINARY keys add rly1 --home $CHAIN_DIR/$CHAINID_1 --recover --keyring-backend=test
echo $RLY_MNEMONIC_2 | $GAIAD_BINARY keys add rly2 --home $CHAIN_DIR/$CHAINID_2 --recover --keyring-backend=test

$NEUTROND_BINARY add-genesis-account $($NEUTROND_BINARY --home $CHAIN_DIR/$CHAINID_1 keys show val1 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_1
$GAIAD_BINARY add-genesis-account $($GAIAD_BINARY --home $CHAIN_DIR/$CHAINID_2 keys show val2 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_2
$NEUTROND_BINARY add-genesis-account $($NEUTROND_BINARY --home $CHAIN_DIR/$CHAINID_1 keys show demowallet1 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_1
$GAIAD_BINARY add-genesis-account $($GAIAD_BINARY --home $CHAIN_DIR/$CHAINID_2 keys show demowallet2 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_2
$NEUTROND_BINARY add-genesis-account $($NEUTROND_BINARY --home $CHAIN_DIR/$CHAINID_1 keys show demowallet3 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_1
$NEUTROND_BINARY add-genesis-account $($NEUTROND_BINARY --home $CHAIN_DIR/$CHAINID_1 keys show rly1 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_1
$GAIAD_BINARY add-genesis-account $($GAIAD_BINARY --home $CHAIN_DIR/$CHAINID_2 keys show rly2 --keyring-backend test -a) 100000000000stake  --home $CHAIN_DIR/$CHAINID_2

echo "Add consumer section..."
$NEUTROND_BINARY add-consumer-section --home $CHAIN_DIR/$CHAINID_1

echo "Creating and collecting gaiad network gentx..."
$GAIAD_BINARY gentx val2 7000000000stake --home $CHAIN_DIR/$CHAINID_2 --chain-id $CHAINID_2 --keyring-backend test
$GAIAD_BINARY collect-gentxs --home $CHAIN_DIR/$CHAINID_2

echo "Changing defaults and ports in app.toml and config.toml files..."
sed -i -e 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT_1"'"#g' $CHAIN_DIR/$CHAINID_1/config/config.toml
sed -i -e 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT_1"'"#g' $CHAIN_DIR/$CHAINID_1/config/config.toml
sed -i -e 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAIN_DIR/$CHAINID_1/config/config.toml
sed -i -e 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAIN_DIR/$CHAINID_1/config/config.toml
sed -i -e 's/index_all_keys = false/index_all_keys = true/g' $CHAIN_DIR/$CHAINID_1/config/config.toml
sed -i -e 's/enable = false/enable = true/g' $CHAIN_DIR/$CHAINID_1/config/app.toml
sed -i -e 's/swagger = false/swagger = true/g' $CHAIN_DIR/$CHAINID_1/config/app.toml
sed -i -e 's#"tcp://0.0.0.0:1317"#"tcp://0.0.0.0:'"$RESTPORT_1"'"#g' $CHAIN_DIR/$CHAINID_1/config/app.toml
sed -i -e 's#":8080"#":'"$ROSETTA_1"'"#g' $CHAIN_DIR/$CHAINID_1/config/app.toml
sed -i -e 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0025stake"/g' $CHAIN_DIR/$CHAINID_1/config/app.toml
sed -i -e 's/enabled = false/enabled = true/g' $CHAIN_DIR/$CHAINID_1/config/app.toml
sed -i -e 's/prometheus-retention-time = 0/prometheus-retention-time = 1000/g' $CHAIN_DIR/$CHAINID_1/config/app.toml


sed -i -e 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT_2"'"#g' $CHAIN_DIR/$CHAINID_2/config/config.toml
sed -i -e 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT_2"'"#g' $CHAIN_DIR/$CHAINID_2/config/config.toml
sed -i -e 's/index_all_keys = false/index_all_keys = true/g' $CHAIN_DIR/$CHAINID_2/config/config.toml
sed -i -e 's/enable = false/enable = true/g' $CHAIN_DIR/$CHAINID_2/config/app.toml
sed -i -e 's/swagger = false/swagger = true/g' $CHAIN_DIR/$CHAINID_2/config/app.toml
sed -i -e 's#"tcp://0.0.0.0:1317"#"tcp://0.0.0.0:'"$RESTPORT_2"'"#g' $CHAIN_DIR/$CHAINID_2/config/app.toml
sed -i -e 's#":8080"#":'"$ROSETTA_2"'"#g' $CHAIN_DIR/$CHAINID_2/config/app.toml
sed -i -e 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0025stake"/g' $CHAIN_DIR/$CHAINID_2/config/app.toml
sed -i -e 's/enabled = false/enabled = true/g' $CHAIN_DIR/$CHAINID_2/config/app.toml
sed -i -e 's/prometheus-retention-time = 0/prometheus-retention-time = 1000/g' $CHAIN_DIR/$CHAINID_2/config/app.toml

# Update host chain genesis to allow x/bank/MsgSend ICA tx execution
sed -i -e 's/\"allow_messages\":.*/\"allow_messages\": [\"\/cosmos.bank.v1beta1.MsgSend\", \"\/cosmos.staking.v1beta1.MsgDelegate\", \"\/cosmos.staking.v1beta1.MsgUndelegate\"]/g' $CHAIN_DIR/$CHAINID_2/config/genesis.json
sed -i -e 's/\"admins\":.*/\"admins\": [\"\/neutron14hj2tavq8fpesdwxxcu44rty3hh90vhujrvcmstl4zr3txmfvw9s5c2epq\"]/g' $CHAIN_DIR/$CHAINID_1/config/genesis.json
