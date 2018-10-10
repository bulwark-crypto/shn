#!/bin/bash

sudo apt -qqy install curl jq
clear

BOOTSTRAPURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep bootstrap.dat.xz | grep browser_download_url | cut -d '"' -f 4)
BOOTSTRAPARCHIVE="bootstrap.dat.xz"

clear
echo "This script will refresh your masternode."
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ -e /etc/systemd/system/bulwarkd.service ]; then
  sudo systemctl stop bulwarkd
else
  su -c "bulwark-cli stop" bulwark
fi

echo "Refreshing node, please wait."

sleep 5

sudo rm -rf /home/bulwark/.bulwark/blocks
sudo rm -rf /home/bulwark/.bulwark/database
sudo rm -rf /home/bulwark/.bulwark/chainstate
sudo rm -rf /home/bulwark/.bulwark/peers.dat

sudo cp /home/bulwark/.bulwark/bulwark.conf /home/bulwark/.bulwark/bulwark.conf.backup
sudo sed -i '/^addnode/d' /home/bulwark/.bulwark/bulwark.conf

echo "Installing bootstrap file..."
wget "$BOOTSTRAPURL" && xz -cd "$BOOTSTRAPARCHIVE" > /home/bulwark/.bulwark/bootstrap.dat && rm "$BOOTSTRAPARCHIVE"

if [ -e /etc/systemd/system/bulwarkd.service ]; then
  sudo systemctl start bulwarkd
else
  su -c "bulwarkd -daemon" bulwark
fi

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window." && echo ""

until [ -n "$(bulwark-cli getconnectioncount 2>/dev/null)"  ]; do
  sleep 1
done

until sudo su -c "bulwark-cli mnsync status 2>/dev/null" bulwark | jq '.IsBlockchainSynced' | grep -q true; do
  echo -ne "Current block: $(sudo su -c "bulwark-cli getinfo" bulwark | jq '.blocks')\\r"
  sleep 1
done

clear

cat << EOL

Now, you need to start your masternode. If you haven't already, please add this
node to your masternode.conf now, restart and unlock your desktop wallet, go to
the Masternodes tab, select your new node and click "Start Alias."

EOL

read -rp "Press Enter to continue after you have done that. " -n1 -s

clear

sleep 1
su -c "/usr/local/bin/bulwark-cli startmasternode local false" bulwark
sleep 1
clear
su -c "/usr/local/bin/bulwark-cli masternode status" bulwark
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""
