#!/bin/bash

#load global variables file
wget --progress=bar:force -q https://raw.githubusercontent.com/NewYorkCoin-NYC/NewYorkCoinNode/master/glob-vars.sh -P /root
source /root/glob-vars.sh
rm -f -v /root/glob-vars.sh

#change working directory
cd $HOME

#do we want to remove newyorkcoin
read -r -p "Do you want to remove NewYorkCoin? (Y/N) " ANSWER
echo
if [[ $ANSWER =~ ^([yY])$ ]]
then
	wget --progress=bar:force $DEBIAN_BASE/$DIST-remove-newyorkcoin.sh -P $HOME
	source $HOME/$DIST-remove-newyorkcoin.sh
	rm -f -v $HOME/$DIST-remove-newyorkcoin.sh
fi

#do we want to remove the http status page
read -r -p "Do you want to remove the http status page? (Y/N) " ANSWER
echo
if [[ $ANSWER =~ ^([yY])$ ]]
then
	wget --progress=bar:force $DEBIAN_BASE/$DIST-remove-statuspage.sh -P $HOME
	source $HOME/$DIST-remove-statuspage.sh
	rm -f -v $HOME/$DIST-remove-statuspage.sh
fi
