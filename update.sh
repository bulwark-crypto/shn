#!/bin/bash

sudo apt -qqy install curl jq
clear

TARBALLURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*ARM" | cut -d '"' -f 4)
TARBALLNAME=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*ARM" | cut -d '"' -f 4 | cut -d "/" -f 9)
BWKVERSION=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*ARM" | cut -d '"' -f 4 | cut -d "/" -f 8)

LOCALVERSION=$(bulwark-cli --version | cut -d " " -f 6)
REMOTEVERSION=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | jq -r ".tag_name")

if [[ "$LOCALVERSION" = "$REMOTEVERSION" ]]; then
  echo "No update necessary."
  exit
fi

clear
echo "This script will update your Secure Home Node to version $BWKVERSION"
echo "It must be run as the 'pi' user."
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

echo "Shutting down masternode..."
sudo systemctl stop bulwarkd

echo "Installing Bulwark $BWKVERSION..."
sudo rm /usr/local/bin/bulwark*
wget "$TARBALLURL"
sudo tar -xzvf "$TARBALLNAME" -C /usr/local/bin
rm "$TARBALLNAME"

# Remove addnodes from bulwark.conf
sudo sed -i '/^addnode/d' /home/bulwark/.bulwark/bulwark.conf

# Add Fail2Ban memory hack if needed
if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
  sudo systemctl restart fail2ban
fi

sudo systemctl start bulwarkd

clear

echo "Your masternode is syncing. Please wait for this process to finish."

until sudo su -c "bulwark-cli mnsync status 2>/dev/null" bulwark | jq '.IsBlockchainSynced' | grep -q true; do
  echo -ne "Current block: $(sudo su -c "bulwark-cli getinfo" bulwark | jq '.blocks')\\r"
  sleep 1
done

clear

echo "Installing Bulwark Autoupdater..."
rm -f /usr/local/bin/bulwarkupdate
curl -o /usr/local/bin/bulwarkupdate https://raw.githubusercontent.com/bulwark-crypto/Bulwark-MN-Install/master/bulwarkupdate
chmod a+x /usr/local/bin/bulwarkupdate

if [ ! -f /etc/systemd/system/bulwarkupdate.service ]; then
cat > /etc/systemd/system/bulwarkupdate.service << EOL
[Unit]
Description=Bulwarks's Masternode Autoupdater
After=network-online.target
[Service]
Type=oneshot
User=root
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/bulwarkupdate
EOL
fi

if [ ! -f /etc/systemd/system/bulwarkupdate.timer ]; then
cat > /etc/systemd/system/bulwarkupdate.timer << EOL
[Unit]
Description=Bulwarks's Masternode Autoupdater Timer

[Timer]
OnBootSec=1d
OnUnitActiveSec=1d 

[Install]
WantedBy=timers.target
EOL
fi

systemctl enable bulwarkupdate.timer
systemctl start bulwarkupdate.timer

clear

cat << EOL

Now, you need to start your masternode. If you haven't already, please add this
node to your masternode.conf now, restart and unlock your desktop wallet, go to
the Masternodes tab, select your new node and click "Start Alias."

EOL

read -rp "Press Enter to continue after you've done that. " -n1 -s

clear

sudo su -c "bulwark-cli masternode status" bulwark

cat << EOL

Secure Home Node update completed.

EOL
