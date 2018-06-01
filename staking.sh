#!/bin/bash

#Ensure bulwarkd is active
if systemctl is-active --quiet bulwarkd; then
	systemctl start bulwarkd
	echo "Setting Up Staking Address.."
else
	echo "Setting Up Staking Address.."
fi

#Adds a line to bulwark.conf to instruct the wallet to stake
if [ "tail ~/.bulwark/bulwark.conf" != "staking=1" ]; then
	echo "staking=1" >> ~/.bulwark/bulwark.conf
else
	echo "Staking Already Active"
fi

#generates new address and assigns it a variable
STAKINGADDRESS=$(bulwark-cli getnewaddress)

#Ask for a password and apply it to a variable
read -e -p "Please enter a password to encrypt your new address/wallet with (KEEP THIS SAFE, THIS CANNOT BE RECOVERED) : " ENCRYPTIONKEY

#Encrypt the new address with the requested password
BIP38=$(bulwark-cli bip38encrypt $STAKINGADDRESS $ENCRYPTIONKEY)
echo "Address successfully encrypted!"

#Encrypt the wallet with the same password
bulwark-cli encryptwallet $ENCRYPTIONKEY
echo "Wallet successfully encrypted!"

#Wait for bulwarkd to close down after wallet encryption
echo "Waiting for bulwarkd to restart..."
until  ! systemctl is-active --quiet bulwarkd; do
    sleep 0.5
done

#Open up bulwarkd again
systemctl start bulwarkd

#Unlocks the wallet for a long time period
bulwark-cli walletpassphrase $ENCRYPTIONKEY 9999999999

#End message with further instructions
cat << EOL
Your wallet has now been set up for staking, please send the coins you wish to stake to ${STAKINGADDRESS}. Once your wallet is synced your coins should begin staking automatically.

To check on the status of your staked coins you can run "bulwark-cli getstakingstatus" and "bulwark-cli getinfo". To see when you receive your rewards from your QT wallet, you can also add a watch-only address from your debug console using "importaddress ${STAKINGADDRESS} StakingRewards".

You can also import the private key for this address in to your QT wallet using the BIP38 tool under settings, just enter the information here with the password you chose at the start.

${BIP38}

Finally, to send the coins elsewhere if you no longer wish to stake them, use "bulwark-cli sendfrom ${STAKINGADDRESS} <Address You Want To Send To> <Amount>" which will return the transaction hash.

All of these instruction will be available from the Github page, and in the Bulwark Discord/Telegram on request!

https://github.com/KaneoHunter/shn/blob/master/README.md#staking-setup

EOL
