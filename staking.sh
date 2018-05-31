#!/bin/bash

#Adds a line to bulwark.conf to instruct the wallet to stake
echo "staking=1" >> ~/.bulwark/bulwark.conf

#generates new address and assigns it a variable
STAKINGADDRESS=$(bulwark-cli getnewaddress)

#Ask for a password and apply it to a variable
read -e -p "Please enter a password to encrypt your new address/wallet with (KEEP THIS SAFE) : " ENCRYPTIONKEY

#Encrypt the new address with the requested password
BIP38=$(bulwark-cli bip38encrypt $STAKINGADDRESS $ENCRYPTIONKEY)
echo "$BIP38"

#Encrypt the wallet with the same password
bulwark-cli encryptwallet $ENCRYPTIONKEY

#After encryption, bulwarkd closes, we ensure it opens again
systemctl start bulwarkd

#Unlocks the wallet for a long time period.
bulwark-cli walletpassphrase $ENCRYPTIONKEY 9999999999

#End message with further instructions
cat << EOL
Your wallet has now been set up for staking, please send the coins you wish to stake to ${STAKINGADDRESS}. Once your wallet is synced your coins should begin staking automatically.

To check on the status of your staked coins you can run "bulwark-cli getstakingstatus" and "bulwark-cli getinfo". To see when you receive your rewards from your QT wallet, you can also add a watch-only address from your debug console using "importaddress ${STAKINGADDRESS} StakingRewards".

You can also import the private key for this address in to your QT wallet using the BIP38 tool under settings, just enter the information here with the password you chose at the start.

${BIP38}

Finally, to send the coins elsewhere if you no longer wish to stake them, use "bulwark-cli sendfrom ${STAKINGADDRESS} <Address You Want To Send To> <Amount>" which will return the transaction hash.

All of these instruction will be available from the Github page, and in the Bulwark Discord/Telegram on request!
EOL
