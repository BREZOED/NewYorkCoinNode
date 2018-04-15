#!/bin/bash

#load global variables file
wget --progress=bar:force -q https://raw.githubusercontent.com/NewYorkCoin-NYC/NewYorkCoinNode/master/glob-vars.sh -P /root
source /root/glob-vars.sh
rm -f -v /root/glob-vars.sh

#change working directory
cd $HOME

#get current version from repository
wget --progress=bar:force $SCRIPT_DL_URL/shared/version -P $HOME

#check version
LOC_VERSION=$(sed -n 1p $HOME/scripts/version) #get the current local version number
REP_VERSION=$(sed -n 1p $HOME/version) #get the current version number from the repository

if [ "$LOC_VERSION" -lt "$REP_VERSION" ]
then
	#stop the newyorkcoin daemon
	echo "We need to update!"
	echo "Stop Litecoind to make sure it does not lock any files"
	systemctl stop newyorkcoind.service

	#remove old newyorkcoind binary
	echo "Removing old newyorkcoind bin file"
	rm -f -v $LITECOIND_BIN_DIR/newyorkcoind
	rm -f -v $LITECOIND_BIN_DIR/newyorkcoin-cli

	#gets arch data
	if test $ARCH -eq "64"
	then
	LITECOIN_DL_URL=$LITECOIN_DL_URL_64
	LITECOIN_VER="$LITECOIN_VER_NO_BIT-linux64"
	else
	LITECOIN_DL_URL=$LITECOIN_DL_URL_32
	LITECOIN_VER="$LITECOIN_VER_NO_BIT-linux32"
	fi

	#download, unpack and move the new newyorkcoind binary
	echo "Downloading, unpacking and moving new Litecoind version to $LITECOIND_BIN_DIR"
	wget --progress=bar:force $LITECOIN_DL_URL -P $HOME
	tar zxvf $HOME/$LITECOIN_VER.tar.gz
	rm -f -v $HOME/$LITECOIN_VER.tar.gz
	cp -f -v $HOME/$LITECOIN_VER_NO_BIT/bin/newyorkcoind $LITECOIND_BIN_DIR
	cp -f -v $HOME/$LITECOIN_VER_NO_BIT/bin/newyorkcoin-cli $LITECOIND_BIN_DIR
	rm -r -f -v $HOME/$LITECOIN_VER_NO_BIT

	#start newyorkcoin daemon
	echo "Starting new newyorkcoind"
	systemctl start newyorkcoind.service

	#remove current and move the new version file
	echo "Removing current version file."
	rm -f -v $HOME/scripts/version
	echo "Moving the new version file."
	mv -v $HOME/version $HOME/scripts
	chmod -R 0600 $HOME/scripts/version
	chown -R root:root $HOME/scripts/version

	#update the node status page and newyorkcoin-node-status.py script if the newyorkcoin-node-status.py file exists
	NODESTATUS_FILE="$HOME/scripts/newyorkcoin-node-status.py"

	if [ -f "$NODESTATUS_FILE" ]
	then

		#remove current website files
		echo "removing current website files"
		rm -f -v $RASPBIAN_WEBSITE_DIR/banner.png
		rm -f -v $RASPBIAN_WEBSITE_DIR/bootstrap.css
		rm -f -v $RASPBIAN_WEBSITE_DIR/favicon.ico
		rm -f -v $RASPBIAN_WEBSITE_DIR/style.css

		#get update the website files
		echo "Updating current website files"
		wget --progress=bar:force $WEBSITE_DL_URL/banner.png -P $RASPBIAN_WEBSITE_DIR
		wget --progress=bar:force $WEBSITE_DL_URL/bootstrap.css -P $RASPBIAN_WEBSITE_DIR
		wget --progress=bar:force $WEBSITE_DL_URL/favicon.ico -P $RASPBIAN_WEBSITE_DIR
		wget --progress=bar:force $WEBSITE_DL_URL/style.css -P $RASPBIAN_WEBSITE_DIR

		#Remove the current newyorkcoin-node-status.py file
		echo "Remove newyorkcoin-node-status.py file"
		rm -f -v $HOME/scripts/newyorkcoin-node-status.py

		#get updated newyorkcoin-node-status.py file
		echo "download new newyorkcoin-node-status.py file"
		wget --progress=bar:force $NODESTATUS_DL_URL -P $HOME/scripts
		chmod -R 0700 $HOME/scripts/newyorkcoin-node-status.py
		chown -R root:root $HOME/scripts/newyorkcoin-node-status.py

		#get the rpcuser and rpcuserpassword from the newyorkcoin.conf file to inject later
		RPC_USER=$(sed -n 1p $LITECOIND_CONF_FILE | cut -c9-39) #get the rpcuser  from the newyorkcoin.conf file
		RPC_PASSWORD=$(sed -n 2p $LITECOIND_CONF_FILE | cut -c13-42) #get the rpcuserpassword from the newyorkcoin.conf file

		#Add $RASPBIAN_WEBSITE_DIR to the new newyorkcoin-node-status.py script
		echo "Add the distributions website dir to the newyorkcoin-nodes-status.py script"
		sed -i -e '13iff = open('"'$RASPBIAN_WEBSITE_DIR/index.html'"', '"'w'"')\' $HOME/scripts/newyorkcoin-node-status.py

		#Add Litecoin rpc user and password to the  new newyorkcoin-node-status.py script
		echo "Add Litecoin rpc user and password to the newyorkcoin-nodes-tatus.py script"
		sed -i -e '10iget_lcd_info = AuthServiceProxy("http://'"$RPC_USER"':'"$RPC_PASSWORD"'@127.0.0.1:9332")\' $HOME/scripts/newyorkcoin-node-status.py #add the rpcuser and rpcpassword to the newyorkcoin-node-status.py script

		#Add a countdown to give newyorkcoind some time to start before updating the nodestatus page to prevent an access denied error
		echo "Start countdown to give newyorkcoind some time to start before updating the node status page."
		cdtime=$((1 * 15))
		while [ $cdtime -gt 0 ]; do
			echo -ne "$cdtime\033[0K\r"
			sleep 1
			: $((cdtime--))
		done

		#update the nodestatus page
		python $HOME/scripts/newyorkcoin-node-status.py
	fi
else
	rm -f -v $HOME/version
	echo "No need to update, exiting."
fi
