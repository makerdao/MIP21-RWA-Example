all            :; dapp --use solc:0.5.12 build
clean          :; dapp clean
test           :; ./test-rwaspell.sh
deploy         :; echo "use deploy-kovan or deploy-mainnet"
deploy-kovan   :; ./scripts/deploy.sh kovan
deploy-mainnet :; ./scripts/deploy.sh mainnet
