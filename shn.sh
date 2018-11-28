#!/bin/bash

sudo apt -qqy install curl
clear

CHARS="/-\\|"
TARBALLURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*ARM" | cut -d '"' -f 4)
TARBALLNAME=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep browser_download_url | grep -e "bulwark-node.*ARM" | cut -d '"' -f 4 | cut -d "/" -f 9)
BOOTSTRAPURL=$(curl -s https://api.github.com/repos/bulwark-crypto/bulwark/releases/latest | grep bootstrap.dat.xz | grep browser_download_url | cut -d '"' -f 4)
BOOTSTRAPARCHIVE="bootstrap.dat.xz"
# BWK-Dash variables.
DASH_BIN_TAR="bwk-dash-1.0.0-linux-arm.tar.gz"
DASH_HTML_TAR="bwk-dash-1.0.0-html.tar.gz"
DASH_PORT="8080"
DASH_VER="v1.0.0"

if [ "$(id -u)" != "0" ]; then
    echo "Sorry, this script needs to be run as root - sudo bash shn.sh"
    exit 1
fi

echo "Preparing installation..."
if ifconfig | grep wlan0 | grep RUNNING; then
  PSK=$(sudo cat /etc/wpa_supplicant/wpa_supplicant.conf | grep -o -o 'psk=".*"' | cut -c 5- | sed 's/"//g')
  SSID=$(sudo cat /etc/wpa_supplicant/wpa_supplicant.conf | grep -o -o 'ssid=".*"' | cut -c 6- | sed 's/"//g')
  NEWPSK=$(wpa_passphrase "$SSID $PSK" | head -4 | tail -1 | cut -c 6-)
  sudo sed -i s/psk=.*$/psk="$NEWPSK"/g /etc/wpa_supplicant/wpa_supplicant.conf
fi

sudo apt-get -y update
sleep 2
sudo apt-get -y upgrade
sleep 2
sudo apt-get -y dist-upgrade
sleep 2
sudo apt-get update -y
sleep 2
sudo apt-get install htop -y
sleep 3
sudo apt-get install nano -y
sleep 3
sudo apt-get install ufw -y
sleep 3
sudo apt-get install fail2ban -y
sleep 3
sudo apt-get install tor -y
sleep 3
sudo apt-get install git -y
sleep 3
sudo apt install xz-utils -y
sleep 3
sudo apt install jq -y
sleep 3
sudo wget --directory-prefix=/etc/fail2ban/ https://raw.githubusercontent.com/bulwark-crypto/shn/master/jail.local
sudo apt install unattended-upgrades -y
sleep 3
sudo sh -c 'echo "Unattended-Upgrade::Allowed-Origins {" >> /etc/apt/apt.conf.d/50unattended-upgrades'
sudo sh -c 'echo "        "${distro_id}:${distro_codename}";" >> /etc/apt/apt.conf.d/50unattended-upgrades'
sudo sh -c 'echo "        "${distro_id}:${distro_codename}-security";" >> /etc/apt/apt.conf.d/50unattended-upgrades'
sudo sh -c 'echo "APT::Periodic::AutocleanInterval "7";" >> /etc/apt/apt.conf.d/20auto-upgrades'
sudo sh -c 'echo "APT::Periodic::Unattended-Upgrade "1";" >> /etc/apt/apt.conf.d/20auto-upgrades'
sudo adduser --gecos "" bulwark --disabled-password > /dev/null
sleep 1
sudo tee /etc/systemd/system/bulwarkd.service << EOL
[Unit]
Description=Bulwarks's distributed currency daemon
After=network.target
[Service]
Type=forking
User=bulwark
WorkingDirectory=/home/bulwark
ExecStart=/usr/local/bin/bulwarkd -conf=/home/bulwark/.bulwark/bulwark.conf -datadir=/home/bulwark/.bulwark
ExecStop=/usr/local/bin/bulwark-cli -conf=/home/bulwark/.bulwark/bulwark.conf -datadir=/home/bulwark/.bulwark stop
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOL
sleep 1
echo "" >> /home/bulwark/.profile
echo "# Bulwark settings" >> /home/bulwark/.profile
sudo sh -c "echo 'GOPATH=/home/bulwark/go' >> /home/bulwark/.profile"
sleep 1
sudo mkdir /home/bulwark/.bulwark
wget "$BOOTSTRAPURL" && xz -cd "$BOOTSTRAPARCHIVE" > /home/bulwark/.bulwark/bootstrap.dat && rm "$BOOTSTRAPARCHIVE"
sudo touch /home/bulwark/.bulwark/bulwark.conf
sudo chown -R bulwark:bulwark /home/bulwark/.bulwark
RPCUSER=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sudo tee -a /home/bulwark/.bulwark/bulwark.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
daemon=1
EOL
sudo ufw allow 9050
sleep 2
sudo ufw allow 52543
sleep 2
sudo ufw allow 8080/tcp
sleep 2
sudo ufw allow http
sleep 2
sudo ufw allow ssh
sleep 2
sudo ufw allow from 127.0.0.1 to 127.0.0.1 port 52541
sleep 2
sudo ufw allow from "$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/' | awk -F"." '{print $1"."$2"."$3".0/24"}')" to any port 22
sleep 2

sudo tee -a /etc/ufw/before.rules << EOL

*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
COMMIT
EOL

yes | sudo ufw enable
sleep 2

# Add Fail2Ban memory hack if needed
if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
  sudo systemctl restart fail2ban
fi

sudo wget "$TARBALLURL"
sleep 2
sudo tar -xzf "$TARBALLNAME" -C /usr/local/bin
sleep 2
sudo rm "$TARBALLNAME"
sleep 2
sudo sh -c 'echo "### TOR CONFIG ###" >> /home/bulwark/.bulwark/bulwark.conf'
sudo sh -c 'echo "onion=127.0.0.1:9050" >> /home/bulwark/.bulwark/bulwark.conf'
sudo sh -c 'echo "onlynet=tor" >> /home/bulwark/.bulwark/bulwark.conf'
sudo sh -c 'echo "bind=127.0.0.1" >> /home/bulwark/.bulwark/bulwark.conf'
sudo sh -c 'echo "listen=1" >> /home/bulwark/.bulwark/bulwark.conf'
sudo sh -c 'echo "dnsseed=0" >> /home/bulwark/.bulwark/bulwark.conf'
sudo sh -c 'echo "### XERONET ROCKET TORRC for BWK ###" >> /etc/tor/torrc'
sudo sh -c 'echo "HiddenServiceDir /var/lib/tor/hidden_service/" >> /etc/tor/torrc'
sudo sh -c 'echo "ClientOnly 1" >> /etc/tor/torrc'
sudo sh -c 'echo "ControlPort 9051" >> /etc/tor/torrc'
sudo sh -c 'echo "NumEntryGuards 4" >> /etc/tor/torrc'
sudo sh -c 'echo "NumDirectoryGuards 3" >> /etc/tor/torrc'
sudo sh -c 'echo "GuardLifetime 2764800" >> /etc/tor/torrc'
sudo sh -c 'echo "GeoIPExcludeUnknown 1" >> /etc/tor/torrc'
sudo sh -c 'echo "EntryNodes 31.185.104.19/32,31.185.104.20/31,46.182.106.190/32,51.15.13.245/32,51.15.43.232/32,51.15.44.197/32,51.15.45.97/32,51.15.46.49/32,51.15.50.133/32,51.15.57.177/32,51.15.57.79/32,51.15.60.255/32,51.15.60.62/32,62.102.148.67/32,62.138.7.171/32,77.109.139.87/32,78.142.140.242/32,80.67.172.162/32,81.7.10.29/32,82.94.251.227/32,85.248.227.163/32,85.248.227.164/31,86.59.119.83/32,86.59.119.88/32,89.234.157.254/32,91.121.23.100/32,94.140.120.44/32,94.242.246.23/32,94.242.246.24/32,94.252.114.48/32,95.142.161.63/32,134.119.3.164/32,171.25.193.20/32,171.25.193.25/32,171.25.193.77/32,171.25.193.78/32,176.10.104.240/32,176.10.104.243/32,176.126.252.11/32,176.126.252.12/32,178.16.208.55/32,178.16.208.56/30,178.16.208.60/31,178.16.208.62/32,178.20.55.16/32,178.20.55.18/32,178.209.42.84/32,185.100.84.82/32,185.100.86.100/32,185.34.33.2/32,185.86.149.75/32,188.118.198.244/32,192.36.27.4/32,192.36.27.6/31,192.42.116.16/32,212.51.156.78/32" >> /etc/tor/torrc'
sudo sh -c 'echo "ExitNodes 31.185.104.19/32,31.185.104.20/31,46.182.106.190/32,51.15.43.232/32,51.15.44.197/32,51.15.45.97/32,51.15.46.49/32,51.15.50.133/32,51.15.57.177/32,51.15.57.79/32,51.15.60.255/32,51.15.60.62/32,62.102.148.67/32,77.109.139.87/32,80.67.172.162/32,85.248.227.163/32,85.248.227.164/31,89.234.157.254/32,94.242.246.23/32,94.242.246.24/32,95.142.161.63/32,171.25.193.20/32,171.25.193.25/32,171.25.193.77/32,171.25.193.78/32,176.10.104.240/32,176.10.104.243/32,176.126.252.11/32,176.126.252.12/32,178.20.55.16/32,178.20.55.18/32,178.209.42.84/32,185.100.84.82/32,185.100.86.100/32,185.34.33.2/32,192.36.27.4/32,192.36.27.6/31,192.42.116.16/32,212.16.104.33/32" >> /etc/tor/torrc'
sudo sh -c 'echo "HiddenServiceDir /var/lib/tor/hidden_service/" >> /etc/tor/torrc'
sudo sh -c 'echo "HiddenServicePort 52543 127.0.0.1:52543" >> /etc/tor/torrc'
sudo sh -c 'echo "HiddenServicePort 80 127.0.0.1:80" >> /etc/tor/torrc'
sudo sh -c 'echo "LongLivedPorts 80,52543" >> /etc/tor/torrc'
sudo sh -c 'echo "### TOR CONF END###" >> /home/bulwark/.bulwark/bulwark.conf'
sleep 3
sudo /etc/init.d/tor stop
sleep 1
sudo touch /etc/cron.d/torcheck
sudo sh -c 'echo "*/5 * * * * root /etc/init.d/tor start > /dev/null 2>&1" >> /etc/cron.d/torcheck' ### CHECK ME or USE CRONTAB -e
sudo rm -R /var/lib/tor/hidden_service
sudo /etc/init.d/tor start
echo "Tor installed, configured and restarted"
sleep 5

# Get the .onion address for use in bwk-dash .env file and
# echo to screen.
ONION_ADDR=$( sudo cat /var/lib/tor/hidden_service/hostname )

echo "Installing BWK-DASH"
#BWK-Dash Setup - START
# Setup systemd service and start.
sudo tee /etc/systemd/system/bwk-dash.service << EOL
[Unit]
Description=Bulwark Home Node Dashboard
After=network.target
[Service]
User=bulwark
Group=bulwark
WorkingDirectory=/home/bulwark/dash
ExecStart=/usr/local/bin/bwk-dash
Restart=always
TimeoutSec=10
RestartSec=35
[Install]
WantedBy=multi-user.target
EOL
sleep 1
# Get binaries and install.
wget https://github.com/bulwark-crypto/bwk-dash/releases/download/$DASH_VER/$DASH_BIN_TAR
sudo tar -zxf $DASH_BIN_TAR -C /usr/local/bin
rm -f $DASH_BIN_TAR
# Copy the html files to the dash folder and create.
wget https://github.com/bulwark-crypto/bwk-dash/releases/download/$DASH_VER/$DASH_HTML_TAR
sudo mkdir -p /home/bulwark/dash
sudo tar -zxf $DASH_HTML_TAR -C /home/bulwark/dash
rm -f $DASH_HTML_TAR
# Create .env file for dashboard api and cron.
cat > /home/bulwark/dash/.env << EOL
DASH_DONATION_ADDRESS=bRc4WCeyYvzcLSkMrAanM83Nc885JyQTMY
DASH_PORT=${DASH_PORT}
DASH_RPC_ADDR=localhost
DASH_RPC_PORT=52541
DASH_RPC_USER=${RPCUSER}
DASH_RPC_PASS=${RPCPASSWORD}
DASH_WEBSITE=/home/bulwark/dash
DASH_DB=/home/bulwark/dash/bwk-dash.db
DASH_TOR=${ONION_ADDR}
EOL
sleep 1
# Cleanup/enforce ownership.
sudo chown -R bulwark:bulwark /home/bulwark/dash
# Setup timer and service for bwk-cron.
sudo tee /etc/systemd/system/bwk-cron.service << EOL
[Unit]
Description=Bulwark Home Node Dashboard - Cron
After=network.target
[Service]
User=bulwark
Group=bulwark
WorkingDirectory=/home/bulwark/dash
ExecStart=/usr/local/bin/bwk-cron
Restart=always
TimeoutSec=10
RestartSec=35
EOL
sleep 1
sudo tee /etc/systemd/system/bwk-cron.timer << EOL
[Unit]
Description=Bulwark Home Node Dashboard - Cron
[Timer]
OnCalendar=*-*-* *:*:00
OnBootSec=35
OnUnitActiveSec=60
[Install]
WantedBy=timers.target
EOL
sleep 1
# Enable service and timer.
sudo systemctl enable bwk-cron.timer
sudo systemctl enable bwk-dash.service
#BWK-Dash Setup - END
sleep 1

cd ~ || exit 1
sleep 1
sudo systemctl enable bulwarkd.service
sleep 1
sudo systemctl start bulwarkd.service
echo "Starting up bulwarkd, please wait"

# Wait for bulwark to finish starting to prevent errors in line 158
until sudo su -c "bulwark-cli getinfo 2>/dev/null | grep 'balance' > /dev/null" bulwark; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 2
    echo -en "${CHARS:$i:1}" "\\r"
  done
done

sudo su -c 'echo "masternodeprivkey=`sudo su -c "bulwark-cli -datadir=/home/bulwark/.bulwark -conf=/home/bulwark/.bulwark/bulwark.conf masternode genkey" bulwark`" >> /home/bulwark/.bulwark/bulwark.conf'
sudo su -c 'echo "masternode=1" >> /home/bulwark/.bulwark/bulwark.conf'
sudo su -c 'echo "externalip=$(sudo cat /var/lib/tor/hidden_service/hostname)" >> /home/bulwark/.bulwark/bulwark.conf'
echo ""

clear

until sudo su -c "bulwark-cli mnsync status 2>/dev/null" bulwark | jq '.IsBlockchainSynced' | grep -q true; do
  echo -ne "Current block: $(sudo su -c "bulwark-cli getinfo" bulwark | jq '.blocks')\\r"
  sleep 1
done

clear 

echo "Daemon Status:"
sudo systemctl status bulwarkd.service | sed -n -e 's/^.*Active: //p'
echo ""
echo "Tor Status:"
curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs
echo ""
echo "Show Onion Address: ${ONION_ADDR}"
echo ""
echo "Show Active Peers:"
bulwark-cli -datadir=/home/bulwark/.bulwark -conf=/home/bulwark/.bulwark/bulwark.conf getpeerinfo | sed -n -e 's/^.*"addr" : //p'
echo ""
echo "Firewall Rules:"
sudo ufw status
echo ""
echo "Fail2Ban:"
sudo systemctl status fail2ban.service | sed -n -e 's/^.*Active: //p'
echo ""
echo "Unattended Updates:"
cat /etc/apt/apt.conf.d/20auto-upgrades
echo ""
echo "Wifi Password hashed:"
sudo cat /etc/wpa_supplicant/wpa_supplicant.conf | grep 'psk='
echo ""
echo "Local Wallet masternode.conf file:"
echo TORNODE "$(sudo cat /var/lib/tor/hidden_service/hostname):52543 $(sudo grep -Po '(?<=masternodeprivkey=).*' /home/bulwark/.bulwark/bulwark.conf)" "$YOURTXINHERE"
echo ""
echo "Important Other Infos:"
echo ""
echo "Bulwark bin dir: /home/bulwark/bulwark"
echo "bulwark.conf: /home/bulwark/.bulwark/bulwark.conf"
echo ""
echo "Start daemon: sudo systemctl start bulwarkd.service"
echo "Restart daemon: sudo systemctl restart bulwarkd.service"
echo "Status of daemon: sudo systemctl status bulwarkd.service"
echo "Stop daemon: sudo systemctl stop bulwarkd.service"
echo "Check bulwarkd status: bulwark-cli getinfo"
echo "Check masternode status: bulwark-cli masternode status"
echo ""
echo "BWK-Dash address: http://$(ifconfig | grep "inet " | grep -v -m1 "127.0.0.1" | awk '{print $2}')"
sleep 5
echo ""
echo "Adding bulwark-cli shortcut to ~/.profile"
echo "alias bulwark-cli='sudo bulwark-cli -config=/home/bulwark/.bulwark/bulwark.conf -datadir=/home/bulwark/.bulwark'" >> /home/pi/.profile
echo "Installation finished."
read -rp "Press Enter to continue, the system will reboot."
sudo rm -rf shn.sh
sudo su -c "cd /home/bulwark/dash && /usr/local/bin/bwk-cron"
sudo chown -R bulwark:bulwark /home/bulwark/dash
sudo reboot
