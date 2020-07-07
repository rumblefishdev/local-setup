#!/bin/bash

set -e

LOG_START='\n\e[1;36m' # new line + bold + color
LOG_END='\n\e[0m' # new line + reset color
DONE_START='\n\e[1;32m' # new line + bold + green
DONE_END='\n\n\e[0m'    # new line + reset

WORKDIR=$PWD

printf "${LOG_START}Starting tBTC deployment...${LOG_END}"

cd "$WORKDIR/relay-genesis"
npm install

# If you want to use BTC testnet with real relay maintaner, uncomment the block
# below and comment the invocation of mock-difficulty.js script.
#
# cd "$WORKDIR/tbtc/solidity/migrations"
# jq --arg forceRelay TestnetRelay '. + {forceRelay: $forceRelay}' relay-config.json > relay-config.json.tmp && mv relay-config.json.tmp relay-config.json
#
# bitcoinTest=$(node "$WORKDIR/relay-genesis/relay-genesis.js")
# BITCOIN_TEST=$(echo "$bitcoinTest" | tail -1)
#
# jq --arg bitcoinTest ${BITCOIN_TEST} '.init.bitcoinTest = $bitcoinTest' relay-config.json > relay-config.json.tmp && mv relay-config.json.tmp relay-config.json
# jq '.init.bitcoinTest |= fromjson' relay-config.json > relay-config.json.tmp && mv relay-config.json.tmp relay-config.json

cd "$WORKDIR/tbtc"

# Run tBTC install script.  Answer with ENTER on emerging prompt.
printf '\n' | ./scripts/install.sh

cd "$WORKDIR/tbtc/solidity"

truffle exec "$WORKDIR/relay-genesis/mock-difficulty.js"

printf "${DONE_START}tBTC deployed successfully!${DONE_END}"

# Initialize KEEP-ECDSA

printf "${LOG_START}Initializing keep-ecdsa...${LOG_END}"

# Get network ID.
NETWORK_ID_OUTPUT=$(truffle exec ./scripts/get-network-id.js)
NETWORK_ID=$(echo "$NETWORK_ID_OUTPUT" | tail -1)

# Extract TBTCSystem contract address.
JSON_QUERY=".networks.\"${NETWORK_ID}\".address"
TBTC_SYSTEM_CONTRACT="$WORKDIR/tbtc/solidity/build/contracts/TBTCSystem.json"
TBTC_SYSTEM_CONTRACT_ADDRESS=$(cat ${TBTC_SYSTEM_CONTRACT} | jq "${JSON_QUERY}" | tr -d '"')

printf "${LOG_START}TBTCSystem contract address is: ${TBTC_SYSTEM_CONTRACT_ADDRESS}${LOG_END}"

cd "$WORKDIR/keep-ecdsa"

# Run keep-ecdsa initialization script. Answer with ENTER on the first prompt
# and with TBTCSystem contract address on the second one.
printf '\n'${TBTC_SYSTEM_CONTRACT_ADDRESS}'\n' | ./scripts/initialize.sh

printf "${DONE_START}keep-ecdsa initialized successfully!${DONE_END}"