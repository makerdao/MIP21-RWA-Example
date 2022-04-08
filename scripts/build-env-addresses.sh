#!/bin/bash
# build-env-addresses.sh

# Loads an address file from a URL and adds checksummed contract addresses to the environment
# Source this script to set envvars
#    `bash ./scripts/build-env-addresses.sh [ network ]`
# Run as script and write to file to save exports to source file
#    `bash ./scripts/build-env-addresses.sh [ network ] > env-addresses-network`

set -eo pipefail

function validate_url() {
  if [[ $(curl -I ${1} 2>&1 | grep -E 'HTTP/(1.1|2) [23][0-9]+') ]]; then
    return 0
  else
    return 1
  fi
}

[ -x "$(command -v jq)" ] || {
  echo "Missing 'jq' command, please install it!" >&2
  exit 1
}

if [ -z "${1}" ]; then
  echo "Please specify the network [ mainnet, goerli, kovan, ces-goerli ] or a file path as an argument." >&2
  [ -z "${PS1}" ] && exit || return
fi

if [ -z "$MCD_ADDRESSES" ]; then
  if [ "${1}" == "mainnet" ]; then
    URL="https://changelog.makerdao.com/releases/mainnet/active/contracts.json"
  elif [ "${1}" == "goerli" ]; then
    URL="https://changelog.makerdao.com/releases/goerli/active/contracts.json"
  elif [ "${1}" == "kovan" ]; then
    URL="https://changelog.makerdao.com/releases/kovan/active/contracts.json"
  elif [ "${1}" == "ces-goerli" ]; then
    URL="https://raw.githubusercontent.com/clio-finance/ces-goerli-mcd/master/contracts.json"
  else
    echo "# Invalid network ${1}" >&2
    [ -z "${PS1}" ] && exit || return
  fi

  if validate_url "${URL}"; then
    echo "# Deployment addresses generated from:" >&2
    echo "# ${URL}" >&2
    MCD_ADDRESSES="$(curl -Ls "${URL}")"
  else
    echo "# Invalid URL ${URL}" >&2
    [ -z "${PS1}" ] && exit || return
  fi
fi

ENV_VARS=$(${BASH_SOURCE%/*}/../lib/shell-utils/bin/json-to-env -x <<<"$MCD_ADDRESSES" | grep -v '^export version')

# If the file was sourced, then set the env vars directly
if [[ $0 != "$BASH_SOURCE" ]]; then
  eval set -- "$ENV_VARS"
else
  echo "$ENV_VARS"
fi
