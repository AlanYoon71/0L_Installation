#!/bin/bash
echo ""
voting=`timeout 2s tail -f ~/.0L/logs/node/current | grep "broadcast to all peers"`
sleep 0.1
echo -e "\e[1m\e[32m============= Broadcasting log =============\e[0m"
echo "$voting"
echo ""
echo ""
notvoting=`timeout 8s tail -f ~/.0L/logs/node/current | grep "currently not connected"`
sleep 0.1
echo -e "\e[1m\e[31m============= Consensus NG log =============\e[0m"
echo "$notvoting"
echo ""
sleep 0.1
if [ -z "$notvoting" ]
then
    export TIME=`date +%Y-%m-%dT%H:%M:%S`
    echo -e "$TIME [INFO] All addresses in active set are voting now. Great!"
else
    echo -e "Current ConsensusDirectSend_Message \e[1m\e[31mUnresponsive \e[0mAddresses"
    echo -e "\e[1m\e[31m========\e[0m"
    echo "$notvoting" | grep -Po 'Peer [^,]+' | cut -d' ' -f2 | sort -u
    echo -e "\e[1m\e[31m========\e[0m"
fi