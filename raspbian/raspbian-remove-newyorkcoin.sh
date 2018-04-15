#!/bin/bash

#stop the newyorkcoin daemon
echo "Stop Litecoind to make sure it does not lock any files"
systemctl stop newyorkcoind.service

#remove the systemd script
echo "Removing the newyorkcoind systemd script"
systemctl disable newyorkcoind.service #reload the systemd startup config
rm -r -f -v $RASPBIAN_SYSTEMD_CONF_DIR/$RASPBIAN_SYSTEMD_CONF_FILE

#remove the newyorkcoind user account and group
echo "Removing the newyorkcoind user and group"
userdel $LITECOIND_USER
groupdel $LITECOIND_GROUP

#check if the newyorkcoin-node-status.py script exists and remove it if true
NODESTATUS_FILE="$HOME/scripts/newyorkcoin-node-status.py"

if [ -f "$NODESTATUS_FILE" ]
then
	#Remove the newyorkcoin-node-status.py file
	echo "Removing the newyorkcoin node status file"
	rm -f -v $NODESTATUS_FILE

	#remove newyorkcoin-node-status.py from cron
	echo "Removing newyorkcoin node status script from cron"
	crontab -l > $HOME/scripts/crontempfile
	sed -i '/newyorkcoin-node-status.py/d' $HOME/scripts/crontempfile
	crontab $HOME/scripts/crontempfile
	rm $HOME/scripts/crontempfile
	pip uninstall python-bitcoinrpc -y #remove python-bitcoinrpc as it is no longer useful without newyorkcoind running
fi

#check if the raspbian-update.sh script exists and remove it if true
RASPBIAN_UPDATE_FILE="$HOME/scripts/raspbian-update.sh"

if [ -f "$RASPBIAN_UPDATE_FILE" ]
then

	#Remove the raspbian-update.sh file
	echo "Removing the raspbian update file"
	rm -f -v $RASPBIAN_UPDATE_FILE

	#remove raspbian-update.sh from cron
	echo "Removing the update script from cron"
	crontab -l > $HOME/scripts/crontempfile
	sed -i '/raspbian-update.sh/d' $HOME/scripts/crontempfile
	crontab $HOME/scripts/crontempfile
	rm $HOME/scripts/crontempfile
fi

#Below we check if the wallet.dat file exists in /home/newyorkcoind/.newyorkcoin. The project specifically lets newyorkcoind run with the --disable wallet option so a wallet.dat
#should not exist in /home/newyorkcoind/.newyorkcoin but if it does for whatever reason we should back it up just in case

#check if the wallet file exists and back it up if true
WALLET_FILE="$HOME/.newyorkcoin/wallet.dat"

if [ -f "$WALLET_FILE" ]
then
        #backup the wallet file
        echo "Backing up the wallet.dat file to /root/backup/newyorkcoind"
        mkdir -p /root/backup/newyorkcoind
        mv -v $WALLET_FILE /root/backup/newyorkcoind/wallet.dat
fi

#remove newyorkcoin specific firewall rules
echo "Removing firewall rules."
ufw delete allow 9333/tcp
iptables -D INPUT -p tcp --syn --dport 9333 -m connlimit --connlimit-above 8 --connlimit-mask 24 -j REJECT --reject-with tcp-reset
iptables -D INPUT -p tcp --syn --dport 9333 -m connlimit --connlimit-above 2 -j REJECT --reject-with tcp-reset
iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 9333 -j ACCEPT

#remove newyorkcoind home directory
echo "Removing the newyorkcoind home directory."
rm -r -f -v $LITECOIND_HOME_DIR
