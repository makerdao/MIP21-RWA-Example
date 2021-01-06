#!/bin/bash
#
# ./scripts/deploy.sh <network>

# shellcheck disable=SC1091
source ./scripts/build-env-addresses.sh "$1" > /dev/null 2>&1

SYMBOL="RWA001"
LETTER="A"
ILK="${SYMBOL}-${LETTER}"
OPERATOR="0xD23beB204328D7337e3d2Fb9F150501fDC633B0e"
TRUST1="0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711"
TRUST2="0xDA0111100cb6080b43926253AB88bE719C60Be13"
ILK_ENCODED=$(seth --to-bytes32 "$(seth --from-ascii ${ILK})")
PRICE=$(seth --to-uint256 "$(seth --to-wei 100000000 ether)")

# build it
SOLC_FLAGS="--optimize --optimize-runs=1" dapp --use solc:0.5.12 build

# tokenize it
RWA_TOKEN=$(dapp create RwaToken)

# route it
RWA_ROUTING_CONDUIT=$(dapp create RwaRoutingConduit "${MCD_GOV}" "${MCD_DAI}")
seth send "${RWA_ROUTING_CONDUIT}" 'hope(address)' "${OPERATOR}"
seth send "${RWA_ROUTING_CONDUIT}" 'kiss(address)' "${TRUST1}"
seth send "${RWA_ROUTING_CONDUIT}" 'kiss(address)' "${TRUST2}"
seth send "${RWA_ROUTING_CONDUIT}" 'rely(address)' "${MCD_PAUSE_PROXY}"
seth send "${RWA_ROUTING_CONDUIT}" 'deny(address)' "${ETH_FROM}"

# join it
RWA_JOIN=$(dapp create AuthGemJoin "${MCD_VAT}" "${ILK_ENCODED}" "${RWA_TOKEN}")
seth send "${RWA_JOIN}" 'rely(address)' "${MCD_PAUSE_PROXY}"

# urn it
RWA_URN=$(dapp create RwaUrn "${MCD_VAT}" "${RWA_JOIN}" "${MCD_JOIN_DAI}" "${RWA_ROUTING_CONDUIT}")
seth send "${RWA_URN}" 'hope(address)' "${OPERATOR}"
seth send "${RWA_URN}" 'rely(address)' "${MCD_PAUSE_PROXY}"
seth send "${RWA_URN}" 'deny(address)' "${ETH_FROM}"

# rely it
seth send "${RWA_JOIN}" 'rely(address)' "${RWA_URN}"

# deny it
seth send "${RWA_JOIN}" 'deny(address)' "${ETH_FROM}"

# connect it
RWA_CONDUIT=$(dapp create RwaConduit "${MCD_GOV}" "${MCD_DAI}" "${RWA_URN}")

# flip it
RWA_FLIPPER=$(dapp create RwaFlipper "${MCD_VAT}" "${MCD_CAT}" "${ILK_ENCODED}")
seth send "${RWA_FLIPPER}" 'rely(address)' "${MCD_PAUSE_PROXY}"
seth send "${RWA_FLIPPER}" 'deny(address)' "${ETH_FROM}"

# price it
RWA_LIQUIDATION_ORACLE=$(dapp create RwaLiquidationOracle)
seth send "${RWA_LIQUIDATION_ORACLE}" 'rely(address)' "${MCD_PAUSE_PROXY}"
seth send "${RWA_LIQUIDATION_ORACLE}" 'deny(address)' "${ETH_FROM}"

# pip it
RWA_PIP=$(dapp create DSValue)
seth send "${RWA_PIP}" 'poke(bytes32)' "${PRICE}"
seth send "${RWA_PIP}" 'setOwner(address)' "${RWA_LIQUIDATION_ORACLE}"
# seth send "${RWA_PIP}" 'setOwner(address)' "${MCD_PAUSE_PROXY}"
# TODO this likely needs a custom authority so both governance and the
# liquidation oracle can set the price.  Right now only one can, which means
# either the price if fixed by governance, which isn't great as we want to give
# more DC to RWA001, or there is a bug in setting the price to 0 in the cull().

# print it
echo "OPERATOR: ${OPERATOR}"
echo "TRUST1: ${TRUST1}"
echo "TRUST2: ${TRUST2}"
echo "ILK: ${ILK}"
echo "${SYMBOL}: ${RWA_TOKEN}"
echo "PIP_${SYMBOL}: ${RWA_PIP}"
echo "MCD_JOIN_${SYMBOL}_${LETTER}: ${RWA_JOIN}"
echo "MCD_FLIP_${SYMBOL}_${LETTER}: ${RWA_FLIPPER}"
echo "${SYMBOL}_${LETTER}_URN: ${RWA_URN}"
echo "${SYMBOL}_${LETTER}_CONDUIT: ${RWA_CONDUIT}"
echo "${SYMBOL}_${LETTER}_ROUTING_CONDUIT: ${RWA_ROUTING_CONDUIT}"
echo "${SYMBOL}_LIQUIDATION_ORACLE: ${RWA_LIQUIDATION_ORACLE}"

# technologic
# https://www.youtube.com/watch?v=D8K90hX4PrE
