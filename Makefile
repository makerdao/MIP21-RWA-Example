all            :; dapp --use solc:0.5.12 build
clean          :; dapp clean
test           :; ./test-rwaspell.sh ${match}
deploy         :; echo "use deploy-mainnet, deploy-kovan, or deploy-goerli"
deploy-kovan   :; ./scripts/deploy.sh kovan
deploy-goerli  :; ./scripts/deploy.sh goerli
deploy-mainnet :; ./scripts/deploy.sh ethlive
