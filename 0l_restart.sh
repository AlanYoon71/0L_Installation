#!/bin/bash
clear
echo ""
echo "=============================="
echo ""
echo "Script by  //-\ ][_ //-\ ][\[ ";
echo ""
echo "=============================="
echo ""
echo "This script was created only for restarting validator."
echo ""
sleep 3
echo "Started."
J=1
K=10
while [ $J -lt $K ]
do
    sleep 60
    HOUR=$(date "+%H")
    MIN=$(date "+%M")
    if [ $MIN == 19 ]
    then
        if [ $MIN -lt 20 ]
        then
            echo "syn1=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:20 && export syn20=$(echo $syn1 | grep -o '[0-9]*') &&
            if [ -z $syn20 ] ; then syn20=0 ; fi
            sleep 1730
        fi
    else
        if [ $MIN == 49 ]
        then
            echo "syn2=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:50 && export syn50=$(echo $syn2 | grep -o '[0-9]*') &&
            if [ -z $syn20 ] ; then syn20=0 ; fi
            if [ -z $syn50 ] ; then syn50=0 ; fi
            sleep 530
            if [ $syn50 == $syn20 ]
            then
                echo "/usr/bin/killall diem-node" | at $HOUR:59 &&
                UP=$(expr $HOUR + 1)
                sleep 55
                if [ $UP -gt 22 ]
                then
                    UP=0
                fi
                echo "~/bin/diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1" | at $UP:00 &&
                MIN=$(date "+%M")
                if [ $MIN == 0 ]
                then
                    echo -e "================= \e[1m\e[33mRestarted!! \e[0m================="
                    echo "Network block height stuck at $syn50"
                    date '+%Y/%m/%d %I:%M %p UTC' --utc
                    echo -e "================= \e[1m\e[33mRestarted!! \e[0m================="
                    sleep 1130
                fi
            else
                echo "Good. Block height is increasing now. $syn20 >>> $syn50"
            fi
        fi
    fi
done