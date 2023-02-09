#!/bin/bash
clear
echo ""
echo "==============================";
echo ""
echo "Script by  //-\ ][_ //-\ ][\[ ";
echo ""
echo "==============================";
echo ""
echo "This script was created only for restarting \"validator\"."
echo ""
TIME=$(date +%Y-%m-%dT%I:%M:%S)
echo "$TIME [INFO] Started."
J=1
K=10
while [ $J -lt $K ]
do
    sleep 5
    HOUR=$(date "+%H") &&
    MIN=$(date "+%M") &&
    E=20
    if [ $MIN == $E ]
    then
        export syn1=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|highest') &&
        export syn20=$(echo $syn1 | grep -o '[0-9]*') &&
        TIME=$(date +%Y-%m-%dT%I:%M:%S)
        echo "$TIME [Block height] $syn20" &&
        if [ -z $syn20 ] ; then syn20=0 ; fi
        sleep 1780
    else
        EEE=50
        if [ $MIN == $EEE ]
        then
            export syn2=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|highest') &&
            export syn50=$(echo $syn2 | grep -o '[0-9]*') &&
            TIME=$(date +%Y-%m-%dT%I:%M:%S)
            echo "$TIME [Block height] $syn50"
            if [ -z $syn50 ] ; then syn50=0 ; fi
            if [ $syn50 == $syn20 ]
            then
                TIME=$(date +%Y-%m-%dT%I:%M:%S)
                echo "$TIME [ERROR] Block height stuck!! Validator will be restarted on the hour."
                export UP=$(expr $HOUR + 1) &&
                sleep 430
                P=1
                PP=10
                while [ $P -lt $PP ]
                do
                    sleep 5
                    MIN=$(date "+%M") &&
                    TT=58
                    if [ $MIN == $TT ]
                    then
                        /usr/bin/killall diem-node &&
                        sleep 2
                        D=$(pgrep diem-node)
                        if [ -z $D ]
                        then 
                            TIME=$(date +%Y-%m-%dT%I:%M:%S)
                            echo "$TIME [INFO] Validator killed successfully."
                            P=15
                        else
                            TIME=$(date +%Y-%m-%dT%I:%M:%S)
                            echo "$TIME [ERROR] Failed to kill validator. <<<"
                        fi
                    fi
                done
                R=1
                RR=10
                while [ $R -lt $RR ]
                do
                    sleep 5
                    MIN=$(date "+%M") &&
                    TTT=0
                    if [ $MIN == $TTT ]
                    then
                        ~/bin/diem-node --config ~/.0L/fullnode.node.yaml >> ~/.0L/logs/node.log 2>&1 &&
                        sleep 5
                        D=$(pgrep diem-node)
                        if [ -n $D ]
                        then
                            TIME=$(date +%Y-%m-%dT%I:%M:%S)
                            echo -e "$TIME [INFO] ========= \e[1m\e[33mRestarted successfully. \e[0m========="
                            DD=$(pgrep tower)
                            if [ -z $DD ]
                            then
                                ~/bin/tower -o start >> $HOME/.0L/logs/tower.log 2>&1
                                sleep 2
                                DD=$(pgrep tower)
                                if [ -n $DD ]
                                then
                                    TIME=$(date +%Y-%m-%dT%I:%M:%S)
                                    echo "$TIME [INFO] Tower restarted, too."
                                fi
                            fi
                            R=15
                            sleep 1080
                        else
                            TIME=$(date +%Y-%m-%dT%I:%M:%S)
                            echo -e "$TIME [ERROR] \e[1m\e[32m>>> Failed to restart... Check and restart your validator manually. <<<\e[0m"
                            R=15
                            sleep 1080
                        fi
                    fi
                done
            fi
        fi
    fi
done