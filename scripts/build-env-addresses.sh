#!/bin/bash
# build-env-addresses.sh

# Loads an address file from a URL and adds checksummed contract addresses to the environment
# Source this script to set envvars
#    `. ./scripts/build-env-addresses.sh [ URL | network ]`
# Run as script and write to file to save exports to source file
#    `./scripts/build-env-addresses.sh [ URL | network ] > env-addresses-network`

function validate_url() {
  if [[ $(curl -I ${1} 2>&1 | grep -E 'HTTP/(1.1|2) [23][0-9]+') ]]; then
    return 0
  else
    return 1
  fi
}

if [[ $_ != "${0}" ]]; then
  # Script was run as source
  SOURCED=1
fi

if [ -z "${1}" ]; then
  echo "Please specify the network [ ethlive, kovan, goerli ] or a file path as an argument."
  [ -z "${PS1}" ] && exit || return
fi

if [ "${1}" == "kovan" ]; then
  URL="https://changelog.makerdao.com/releases/kovan/active/contracts.json"
elif [ "${1}" == "goerli" ]; then
  URL="https://gist.githubusercontent.com/gbalabasquer/b26dbda6c228f412bbcc5d34560f7241/raw/d57a914e6129ffe7d99b9394ab746ec5931372e8/goerli_addresses.json"
elif [ "${1}" == "ethlive" ]; then
  URL="https://changelog.makerdao.com/releases/mainnet/active/contracts.json"
else
  URL="${1}"
fi

if validate_url "${URL}"; then
  echo "# Deployment addresses generated from:"
  echo "# ${URL}"
  ADDRESSES_RAW="$(curl -Ls "${URL}")"
else
  echo "# Invalid URL ${URL}"
  [ -z "${PS1}" ] && exit || return
fi

OUTPUT=$(jq -r 'to_entries | map(.key + "|" + (.value | tostring)) | .[]' <<<"${ADDRESSES_RAW}" | \
  while IFS='|' read -r key value; do
    PAIR="${key}=$(seth --to-checksum-address "${value}")"
    echo "${PAIR}"
  done
)

for pair in $OUTPUT
do
  if [[ $SOURCED == 1 ]]; then
    echo "${pair}"
    export "${pair?}"
  else
    echo "export ${pair}"
  fi
done
