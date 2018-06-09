#!/bin/bash

#Simple check to make sure the bulwarkd sync process is finished, so it isn't interrupted and forced to start over later.'
echo "Checking Bulwarkd status. The script will begin setting up staking once bulwarkd has finished syncing. Please allow this process to finish."
until su -c "bulwark-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\" : true' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 2
    echo -en "${CHARS:$i:1}" "\r"
  done
done

#Ensure bulwarkd is active
if systemctl is-active --quiet bulwarkd; then
	systemctl start bulwarkd
	echo "Setting Up Staking Address.."
else
	echo "Setting Up Staking Address.."
fi

#If the line does not already exist, adds a line to bulwark.conf to instruct the wallet to stake
if if grep -Fxq "staking=1" ~/.bulwark/bulwark.conf; then
	echo "Staking Already Active"
else
	echo "staking=1" >> ~/.bulwark/bulwark.conf
fi

#Generates new address and assigns it a variable
STAKINGADDRESS=$(bulwark-cli getnewaddress)

#Ask for a password and apply it to a variable and confirm it.
ENCRYPTIONKEY=1
ENCRYPTIONKEYCONF=2
until [ $ENCRYPTIONKEY = $ENCRYPTIONKEYCONF ]; do
	read -e -p -s "Please enter a password to encrypt your new staking address/wallet with, you will not see what you type appear. (KEEP THIS SAFE, THIS CANNOT BE RECOVERED) : " ENCRYPTIONKEY
	read -e -p -s "Please confirm your password : " ENCRYPTIONKEYCONF
		if [ $ENCRYPTIONKEY != $ENCRYPTIONKEYCONF ]; then
			echo "Your passwords do not match, please try again."
		else
			echo "Password set."
		fi
done


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
bulwark-cli walletpassphrase $ENCRYPTIONKEY 9999999999 true

#Write readme file with further info/instructions.
touch ~/.bulwark/StakingInfoReadMe.txt
cat > ~/.bulwark/StakingInfoReadMe.txt << EOL
Your wallet has now been set up for staking, please send the coins you wish to stake to ${STAKINGADDRESS}. Once your wallet is synced your coins should begin staking automatically.

To check on the status of your staked coins you can run "bulwark-cli getstakingstatus" and "bulwark-cli getinfo". To see when you receive your rewards from your QT wallet, you can also add a watch-only address from your debug console using "importaddress ${STAKINGADDRESS} StakingRewards".

You can also import the private key for this address in to your QT wallet using the BIP38 tool under settings, just enter the information here with the password you chose at the start.

${BIP38}

Finally, to send the coins elsewhere if you no longer wish to stake them, use "bulwark-cli sendfrom ${STAKINGADDRESS} <Address You Want To Send To> <Amount>" which will return the transaction hash.

All of these instruction will be available from the Github page, and in the Bulwark Discord/Telegram on request!

https://github.com/KaneoHunter/shn/blob/staking/README.md#staking-setup

EOL
