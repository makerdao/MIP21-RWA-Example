#!/bin/bash
#
# ./scripts/deploy.sh <network>

set -e

[[ "$1" == "ethlive" || "$1" == "kovan" ]] || { echo "Please specify the network [ ethlive, kovan ]."; exit 1; }
[[ "$ETH_RPC_URL" && "$(seth chain)" == "$1" ]] || { echo "Please set a $1 ETH_RPC_URL"; exit 1; }

# shellcheck disable=SC1091
source ./scripts/build-env-addresses.sh "$1" > /dev/null 2>&1

export ETH_GAS=6000000

SYMBOL="RWA002"
LETTER="A"
ILK="${SYMBOL}-${LETTER}"
[[ -z "OPERATOR" ]] && OPERATOR="0xD23beB204328D7337e3d2Fb9F150501fDC633B0e"

# kovan only
TRUST1="0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711"
TRUST2="0xDA0111100cb6080b43926253AB88bE719C60Be13"

ILK_ENCODED=$(seth --to-bytes32 "$(seth --from-ascii ${ILK})")

# build it
dapp --use solc:0.5.12 build

[[ -z "$NAME" ]] && NAME="RWA-001";
[[ -z "$SYMBOL" ]] && SYMBOL="RWA001";

# tokenize it
RWA_TOKEN=$(dapp create "src/RwaToken.sol:RwaToken" \"$NAME\" \"$SYMBOL\")
seth send "${RWA_TOKEN}" 'transfer(address,uint256)' "$OPERATOR" "$(seth --to-wei 1.0 ether)"

# route it
[[ -z "$RWA_OUTPUT_CONDUIT" ]] && RWA_OUTPUT_CONDUIT=$(dapp create RwaOutputConduit "${MCD_GOV}" "${MCD_DAI}")

if [ "$RWA_OUTPUT_CONDUIT" != "$OPERATOR" ]; then
    seth send "${RWA_OUTPUT_CONDUIT}" 'rely(address)' "${MCD_PAUSE_PROXY}"
    if [ "$1" == "kovan" ]; then
        seth send "${RWA_OUTPUT_CONDUIT}" 'kiss(address)' "${TRUST1}"
        seth send "${RWA_OUTPUT_CONDUIT}" 'kiss(address)' "${TRUST2}"
    fi
    seth send "${RWA_OUTPUT_CONDUIT}" 'deny(address)' "${ETH_FROM}"
fi

# join it
RWA_JOIN=$(dapp create AuthGemJoin "${MCD_VAT}" "${ILK_ENCODED}" "${RWA_TOKEN}")
seth send "${RWA_JOIN}" 'rely(address)' "${MCD_PAUSE_PROXY}"

# urn it
RWA_URN=$(dapp create RwaUrn "${MCD_VAT}" "${MCD_JUG}" "${RWA_JOIN}" "${MCD_JOIN_DAI}" "${RWA_OUTPUT_CONDUIT}")
seth send "${RWA_URN}" 'rely(address)' "${MCD_PAUSE_PROXY}"
seth send "${RWA_URN}" 'deny(address)' "${ETH_FROM}"

# rely it
seth send "${RWA_JOIN}" 'rely(address)' "${RWA_URN}"

# deny it
seth send "${RWA_JOIN}" 'deny(address)' "${ETH_FROM}"

# connect it
[[ -z "RWA_INPUT_CONDUIT" ]] && RWA_INPUT_CONDUIT=$(dapp create RwaInputConduit "${MCD_GOV}" "${MCD_DAI}" "${RWA_URN}")

# price it
if [ ! -n "$MIP21_LIQUIDATION_ORACLE" ]; then
    MIP21_LIQUIDATION_ORACLE=$(dapp create RwaLiquidationOracle "${MCD_VAT}" "${MCD_VOW}")
    seth send "${MIP21_LIQUIDATION_ORACLE}" 'rely(address)' "${MCD_PAUSE_PROXY}"
    seth send "${MIP21_LIQUIDATION_ORACLE}" 'deny(address)' "${ETH_FROM}"
fi

# print it
echo "OPERATOR: ${OPERATOR}"
if [ "$1" == "kovan" ]; then
    echo "TRUST1: ${TRUST1}"
    echo "TRUST2: ${TRUST2}"
fi
echo "ILK: ${ILK}"
echo "${SYMBOL}: ${RWA_TOKEN}"
echo "MCD_JOIN_${SYMBOL}_${LETTER}: ${RWA_JOIN}"
echo "${SYMBOL}_${LETTER}_URN: ${RWA_URN}"
echo "${SYMBOL}_${LETTER}_INPUT_CONDUIT: ${RWA_INPUT_CONDUIT}"
echo "${SYMBOL}_${LETTER}_OUTPUT_CONDUIT: ${RWA_OUTPUT_CONDUIT}"
echo "MIP21_LIQUIDATION_ORACLE: ${MIP21_LIQUIDATION_ORACLE}"

# technologic
# https://www.youtube.com/watch?v=D8K90hX4PrE
