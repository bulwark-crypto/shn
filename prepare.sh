#!/bin/#!/usr/bin/env bash
clear

echo "Updating system..."
sleep 1
sudo apt-get update -y
sleep 1
echo "Upgrading system..."
sleep 1
sudo apt-get upgrade -y
sleep 1
echo "Running distupgrade..."
sleep 1
sudo apt-get dist-upgrade -y
sleep 1
echo "Downloading SHN installer..."
sleep 1
sudo wget https://raw.githubusercontent.com/KaneoHunter/shn/staking/shn.sh
sudo chmod 777 shn.sh
echo "Expanding filesystem..."
sudo raspi-config nonint do_expand_rootfs
sleep 1
echo "Setting GPU memory..."
sudo raspi-config nonint do_memory_split 16
read -e -p "Would you like to set up your Secure Home Node with staking? [N/y] : " STAKING
if [[ ("$STAKING" == "y" || "$STAKING" == "Y") ]]; then
	sudo wget https://raw.githubusercontent.com/KaneoHunter/shn/staking/staking.sh
	sudo chmod 777 staking.sh
	clear
else
clear
fi


cat << EOL

In the next step, you will be asked to enter a new password and confirm it.
The password you type in will not be shown on screen, this is normal.

EOL

sudo passwd pi

clear

echo "Rebooting..."

sleep 1
sudo reboot
