#!/bin/bash

clear
echo ""
echo ""
echo ""
echo "==============================";
echo ""
echo "Script by  //-\ ][_ //-\ ][\[ ";
echo ""
echo "==============================";
echo ""
echo "This script was created only for restarting validator."
echo ""
sleep 3
echo "Started."
echo ""
echo ""
J=1
K=10
while [ $J -lt $K ]
do
    sleep 60
    HOUR=$(date "+%H") &&
    MIN=$(date "+%M") &&
    if [ $MIN == 18 ]
    then
        echo "syn1=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:20 && 
        F=1
        FF=10
        while [ $F -lt $FF ]
        do
            sleep 3
            MIN=$(date "+%M") &&
            if [ $MIN == 20 ]
            then
                echo ""
                export syn20=$(echo $syn1 | grep -o '[0-9]*') &&
                echo "Current height : $syn20"
                echo ""
                F=15
            fi
        done
        if [ -z $syn20 ] ; then syn20=0 ; fi
        sleep 1760
    else
        if [ $MIN == 48 ]
        then
            echo "syn2=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:50 &&
            G=1
            GG=10
            while [ $G -lt $GG ]
            do
                sleep 3
                MIN=$(date "+%M") &&
                if [ $MIN == 50 ]
                then
                    echo ""
                    export syn50=$(echo $syn2 | grep -o '[0-9]*') &&
                    echo "Current height : $syn50"
                    echo ""
                    G=15
                fi
            done
            if [ -z $syn20 ] ; then syn20=0 ; fi
            if [ -z $syn50 ] ; then syn50=0 ; fi
            if [ $syn50 == $syn20 ]
            then
                echo ">>> Block height stuck at $syn50 !! <<<"
                echo ""
                echo "Your validator will be restarted on the hour."
                echo ""
                echo ""
                sleep 500
                echo "/usr/bin/killall diem-node" | at $HOUR:59 &&
                P=1
                PP=10
                while [ $P -lt $PP ]
                do
                    sleep 3
                    MIN=$(date "+%M") &&
                    if [ $MIN == 59 ]
                    then
                        sleep 3
                        echo ""
                        pgrep diem-node || echo "Validator killed" &&
                        echo ""
                        P=15
                    fi
                done
                UP=$(expr $HOUR + 1) &&
                if [ $UP -gt 22 ]
                then
                    UP=0
                fi
                echo "~/bin/diem-node --config ~/.0L/fullnode.node.yaml >> ~/.0L/logs/node.log 2>&1" | at $UP:00 &&
                R=1
                RR=10
                while [ $R -lt $RR ]
                do
                    sleep 3
                    MIN=$(date "+%M")
                    if [ $MIN == 0 ]
                    then
                        echo "Network block height stuck at $syn50"
                        date '+%Y/%m/%d %I:%M %p UTC' --utc
                        echo -e "================= \e[1m\e[33mRestarted!! \e[0m================="
                        R=15
                        sleep 1080
                    fi
                done
            else
                echo "Block height is increasing now. $syn20 >>> $syn50"
                echo ""
                echo ""
            fi
        fi
    fi
done