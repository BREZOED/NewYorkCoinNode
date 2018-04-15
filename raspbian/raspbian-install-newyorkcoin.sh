#!/bin/bash

#change working directory
cd $HOME

#add a user account for newyorkcoind
echo "Adding unprivileged user account for newyorkcoind, building the needed folder structure and setting folder permissions"
useradd -s /usr/sbin/nologin $NEWYORKCOIND_USER

#install ufw firewall configuration package
echo "Installing firewall configuration tool"
apt-get install ufw -y

#allow needed firewall ports
echo "Setting up firewall ports and enable firewall"
ufw allow ssh
ufw allow 9333/tcp
iptables -A INPUT -p tcp --syn --dport 9333 -m connlimit --connlimit-above 8 --connlimit-mask 24 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp --syn --dport 9333 -m connlimit --connlimit-above 2 -j REJECT --reject-with tcp-reset
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 9333 -j ACCEPT
ufw --force enable

#create home directory
mkdir -v -p $NEWYORKCOIND_HOME_DIR
chmod -R 0755 $NEWYORKCOIND_HOME_DIR
chown -R $NEWYORKCOIND_USER:$NEWYORKCOIND_GROUP $NEWYORKCOIND_HOME_DIR
#create data directory
mkdir -v -p $NEWYORKCOIND_DATA_DIR
chmod -R 0700 $NEWYORKCOIND_DATA_DIR
chown -R $NEWYORKCOIND_USER:$NEWYORKCOIND_GROUP $NEWYORKCOIND_DATA_DIR
#create conf file
touch $NEWYORKCOIND_CONF_FILE
chmod -R 0600 $NEWYORKCOIND_CONF_FILE
chown -R $NEWYORKCOIND_USER:$NEWYORKCOIND_GROUP $NEWYORKCOIND_CONF_FILE
#create bin directory
mkdir -v -p $NEWYORKCOIND_BIN_DIR
chmod -R 0700 $NEWYORKCOIND_BIN_DIR
chown -R $NEWYORKCOIND_USER:$NEWYORKCOIND_GROUP $NEWYORKCOIND_BIN_DIR

#create newyorkcoin.conf file
echo "Creating the newyorkcoin.conf file"
echo "rpcuser=$RPC_USER" >> $NEWYORKCOIND_CONF_FILE
echo "rpcpassword=$RPC_PASSWORD" >> $NEWYORKCOIND_CONF_FILE
echo "rpcallowip=127.0.0.1" >> $NEWYORKCOIND_CONF_FILE
echo "server=1" >> $NEWYORKCOIND_CONF_FILE
echo "daemon=1" >> $NEWYORKCOIND_CONF_FILE
echo "disablewallet=1" >> $NEWYORKCOIND_CONF_FILE
echo "maxconnections=$CON_TOTAL" >> $NEWYORKCOIND_CONF_FILE
echo "addnode=$selectedarray_one" >> $NEWYORKCOIND_CONF_FILE
echo "addnode=$selectedarray_two" >> $NEWYORKCOIND_CONF_FILE

#setup dependencies
echo "Installing dependencies required for building NewYorkCoin"
sudo apt-get install autoconf libtool libssl-dev libboost-all-dev libminiupnpc-dev -y
sudo apt-get install qt4-dev-tools libprotobuf-dev protobuf-compiler libqrencode-dev -y

#setup berkleydb and other build dependencies
echo "Setting up berkleydb"
wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
tar -xzvf db-4.8.30.NC.tar.gz
cd db-4.8.30.NC/build_unix; ../dist/configure --enable-cxx
make -j2
sudo make install

#build newyorkcoind
echo "Building NewYorkCoin"
cd ..
git clone https://github.com/newyorkcoin-project/newyorkcoin.git
cd newyorkcoin/
./autogen.sh
./configure CPPFLAGS="-I/usr/local/BerkeleyDB.4.8/include -O2" LDFLAGS="-L/usr/local/BerkeleyDB.4.8/lib"
make -j2
sudo make install

#Move the already built newyorkcoind binary
echo "Moving newyorkcoind to $NEWYORKCOIND_BIN_DIR"
cp -f -v newyorkcoind $NEWYORKCOIND_BIN_DIR
cp -f -v newyorkcoin-cli $NEWYORKCOIND_BIN_DIR

#add newyorkcoind to systemd so it starts on system boot
echo "Adding NewYorkCoind systemd script to make it start on system boot"
wget --progress=bar:force $RASPBIAN_SYSTEMD_DL_URL -P $RASPBIAN_SYSTEMD_CONF_DIR
chmod -R 0644 $RASPBIAN_SYSTEMD_CONF_DIR/$RASPBIAN_SYSTEMD_CONF_FILE
chown -R root:root $RASPBIAN_SYSTEMD_CONF_DIR/$RASPBIAN_SYSTEMD_CONF_FILE
systemctl enable newyorkcoind.service #enable newyorkcoind systemd config file

#do we want to predownload bootstrap.dat
read -r -p "Do you want to download the bootstrap.dat file? If you choose yes your initial blockhain sync will most likely be faster but will take up some extra space on your hard drive (Y/N) " ANSWER
echo
if [[ $ANSWER =~ ^([yY])$ ]]
then
	echo "Downloading bootstrap.dat, this can take a moment"
	wget --progress=bar:force $BOOTSTRAP_DL_LOCATION -P $HOME/.newyorkcoin
fi

#start newyorkcoin daemon
echo "Starting newyorkcoind"
systemctl start newyorkcoind.service
