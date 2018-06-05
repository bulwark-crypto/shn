# Bulwark Secure Home Node Installer

## Table of contents
- [Requirements](#requirements)
- [Generating your Masternode Output](#generating-your-masternode-output)
- [Connecting your SHN to your network](#connecting-your-shn-to-your-network)
  * [Connecting via ethernet](#connecting-via-ethernet)
  * [Connecting via Wi-fi](#connecting-via-wi-fi)
    + [Monitor & Keyboard](#monitor---keyboard)
    + [microSD card reader](#microsd-card-reader)
- [Finding your SHN on your network](#finding-your-shn-on-your-network)
  * [Windows](#windows)
  * [macOS](#macos)
  * [Linux](#linux)
- [Installation](#installation)
  * [Staking](#staking setup)
- [Updates](#updates)

## Requirements
To connect your node, you need either a network router with a free RJ-45 port and an ethernet cable or a router running a 2.4Ghz Wi-fi network. If you want to connect via Wi-fi, you will also need either a monitor that supports HDMI (along with a HDMI cable) and a keyboard, or a microSD card reader that works with your computer.

## Generating your Masternode Output

Run this command to get your output information:

```bash
masternode outputs
```

-Copy both the transaction id and output id to a text file.

## Connecting your SHN to your network
To connect your home node, you have two options: ethernet and Wi-fi.

### Connecting via ethernet
Simply plug in an ethernet cable running to your router into the Raspberry Pi before you connect the power cable. Once you've done that, proceed to [Finding your SHN on your network](#finding-your-shn-on-your-network).

### Connecting via Wi-fi
To set up Wi-fi, you can either connect your SHN to a monitor and keyboard **OR** use a microSD card reader.

#### Monitor & Keyboard
Connect your monitor to the Raspberry Pi with an HDMI cable and plug in a USB keyboard. Connect power to the Raspberry Pi, wait for it to boot up, then log in with the default credentials - user "pi", password "raspberry"

Once you are logged in, run the command
```
sudo raspi-config
```
You will see a graphical interface. First, select "Network Options", then "Wi-fi". In the following screens, select your country (this is necessary in order to use the correct frequencies), then enter your Wi-fi SSID (it's name) and the password. Once you are done, select "Finish" and restart your Raspberry Pi. Then proceed to [Finding your SHN on your network](#finding-your-shn-on-your-network).

#### microSD card reader
Put the microSD card from the Raspberry Pi into your card reader and connect it with your computer. In the root directory of the SD card, create a text file called _wpa_supplicant.conf_ and add the following text to it:
```
country=YOURCOUNTRYCODE
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev update_config=1
network={
       ssid="YOURNETWORKSSID"
       psk="YOURNETWORKPASSWORD"
       key_mgmt=WPA-PSK
    }
```

Replace _YOURCOUNTRYCODE_ with the [two letter ISO code](https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes) of your country, _YOURNETWORKSSID_ with the name of your wireless network and _YOURNETWORKPASSWORD_ with the password of your wireless network (the password will be encrypted during the installation). Eject the SD card, put it back into your Raspberry Pi and connect the power cable, then proceed to [Finding your SHN on your network](#finding-your-shn-on-your-network)

## Finding your SHN on your network
Next, you need to find the IP address your SHN has been assigned by your router. How you do this depends on your operating system.

### Windows
Download the [Adafruit Pi Finder](https://github.com/adafruit/Adafruit-Pi-Finder/releases) for Windows and run it. It will detect your Raspberry Pi and allow you to connect by clicking the "Terminal" button. Proceed to [Installation](#installation).

### macOS
Open Terminal.app and run the following command:
```
ping raspberrypi.local -c1 | head -1 | awk -F " " '{print $3}'
```
You should see a single line containing the IP address of your home node.

If you don't get an address, use the Linux command below.

### Linux
Open a shell and run the following command:
```
arp -na | grep -i b8:27:eb | head -1 | awk -F ' ' '{print $2}'
```
You should see a single line containing the IP address of your home node.

## Installation
Now you're ready to install! Using [Putty](https://www.putty.org/) or a terminal, connect to your SHN using the address you found in the last step and the username "pi" - the default password is "raspberry" - don't worry, we will change this in a bit.

Once you are logged in, run this line:

```
bash <( wget -qO - https://raw.githubusercontent.com/bulwark-crypto/shn/master/prepare.sh )
```

The installer will prepare some things, then ask you to change your password. After that, your Raspberry will reboot.
Wait for a minute, log into your Raspberry again, then run this command:

```
sudo bash shn.sh
```

Now the Secure Home Node will be installed. After a while, you will see the following line:

```
I will open the getinfo screen for you in watch mode now, close it with CTRL + C once we are fully synced.
```

Then you will see the status of bulwarkd syncing. Once the sync is complete (when the number of blocks displayed is up to the current block height), press `Ctrl+c` to finish the installation. You will be shown some information, among that the configuration line you need to add your your _masternode.conf_ on your local wallet. In this configuration lined, replace YOURTXINHERE with the transaction id and output id you got earlier.

Press Enter to restart one more time.

While the Raspberry Pi is rebooting, add the line you got from the script to _masternode.conf_, restart your wallet, open the debug console and start your masternode with the command

```
startmasternode alias false <mymnalias>
```

where _<mymnalias\>_ is the name of your masternode, TORNODE by default.

Congratulations, you're done!

## Updates
To update your Homenode to the newest version of the Bulwark Protocol simply paste the following line in your terminal:
```
bash <( curl https://raw.githubusercontent.com/bulwark-crypto/shn/master/update.sh )
```
## Staking Setup

Once your bulwarkd service is completely synced, you can run the following command to create a wallet address for staking:

```
bash <( curl https://raw.githubusercontent.com/KaneoHunter/shn/master/staking.sh )
```

This script will ask for a password, create a fresh address, encrypt the address and wallet with that password, enable staking, start bulwarkd again (without interrupting your Masternode), and finally unlock the wallet.

You can then send any amount of coins to this address, and it will be staked automatically until removed.

After the script has been run, you can use:

```
bulwark-cli getstakingstatus
```
and
```
bulwark-cli getinfo
```

to check on the current status of whether staking is working correctly.

Furthermore, the script will output a address, and encryption key, which can be imported to your QT wallet using the BIP38 tool. This will allow you to use the address as part of your usual wallet while allowing the funds to be staked while the wallet is closed.

Alternatively, if you want to ensure your coins stay in the right address during use, you can use the address as "watch-only" by entering the following command in to your QT wallet debug console.

```
importaddress ${STAKINGADDRESS} StakingRewards
```

Finally, to remove your coins from this address, you can either add the address as described above with the BIP38 tool and send the funds to a new address via coin control, or you can use the below RPC command to create and send a transaction to a new address:

```
bulwark-cli sendfrom <Address You Are Staking From> <Address You Are Sending To> <Amount To Send>
```

If you have any further questions or issues, send a message to us in the Discord or Telegram and we will be happy to help.
