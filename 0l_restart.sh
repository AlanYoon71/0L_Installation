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
export TIME=`date +%Y-%m-%dT%I:%M:%S`
echo "$TIME [INFO] Started."
J=1
K=10
while [ $J -lt $K ]
do
    sleep 5
    export HOUR=`date "+%H"` &&
    export MIN=`date "+%M"` &&
    ACTION1=20
    if [ $MIN == $ACTION1 ]
    then
        export syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|highest'` &&
        export local1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|synced'` &&
        if [ -z $syn1 ] && [ -z $local1 ]
        then
            pgrep diem-node || ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 &
            echo "$TIME [WARN] Validator is already stopped status. Restarted."
        fi
        sleep 2
        export TIME=`date +%Y-%m-%dT%I:%M:%S` &&
        export syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|highest'` &&
        export local1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|synced'` &&
        export syn20=`echo $syn1 | grep -o '[0-9]*'` &&
        export local20=`echo $local1 | grep -o '[0-9]*'` &&
        export lag20=`expr $local20 - $syn20` &&
        echo "$TIME [INFO] Block height : $syn20" &&
        if [ $lag20 -lt -100 ]
        then
            echo "$TIME [INFO] Sync lag : \e[1m\e[32m$lag20\e[0m"
        else
            echo "$TIME [INFO] Fully synced."
        fi
        sleep 1780
    else
        ACTION2=50
        if [ $MIN == $ACTION2 ]
        then
            export syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|highest'` &&
            export local2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|synced'` &&
            if [ -z $syn2 ] && [ -z $local2 ]
            then
                pgrep diem-node || ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 &
                echo "$TIME [WARN] Validator is already stopped status. Restarted."
            fi
            sleep 2            
            export TIME=`date +%Y-%m-%dT%I:%M:%S` &&
            export syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|highest'` &&
            export local2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep -E 'diem_state_sync_version{type=|synced'` &&            
            export syn50=`echo $syn2 | grep -o '[0-9]*'` &&
            export local50=`echo $local2 | grep -o '[0-9]*'` &&
            export lag50=`expr $local50 - $syn50` &&
            echo "$TIME [INFO] Block height : $syn50" &&
            if [ $lag50 -lt -100 ]
            then
                echo "$TIME [INFO] Sync lag : \e[1m\e[32m$lag50\e[0m"
            else
                echo "$TIME [INFO] Fully synced."
            fi
            if [ $syn50 == $syn20 ]
            then
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                echo "$TIME [WARN] Block height stuck!!"
                export UP=`expr $HOUR + 1` &&
                sleep 430
                P=1
                PP=10
                while [ $P -lt $PP ]
                do
                    sleep 5
                    export MIN=`date "+%M"` &&
                    ACTION3=58
                    if [ $MIN == $ACTION3 ]
                    then
                        export TIME=`date +%Y-%m-%dT%I:%M:%S`
                        /usr/bin/killall diem-node &&
                        sleep 2
                        export D=`pgrep diem-node`
                        if [ -z $D ]
                        then 
                            echo "$TIME [INFO] Validator stopped."
                            P=15
                        else
                            echo "$TIME [ERROR] \e[1m\e[32m>>> Failed to kill diem-node... Check and kill your validator manually. <<<\e[0m"
                            P=15
                        fi
                    fi
                done
                R=1
                RR=10
                while [ $R -lt $RR ]
                do
                    sleep 5
                    export MIN=`date "+%M"` &&
                    ACTION4=00
                    if [ $MIN == $ACTION4 ]
                    then
                        export TIME=`date +%Y-%m-%dT%I:%M:%S`
                        ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 &
                        sleep 5
                        export D=`pgrep diem-node`
                        if [ -z $D ]
                        then
                            echo -e "$TIME [ERROR] \e[1m\e[32m>>> Failed to restart... Check and restart your validator manually. <<<\e[0m"
                            R=15
                            sleep 1080
                        else
                            echo -e "$TIME [INFO] ========= \e[1m\e[32mValidator restarted. \e[0m========="
                            export DD=`pgrep tower`
                            if [ -z $DD ]
                            then
                                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                                echo "$TIME [WARN] Tower disconnected!!"
                                ~/bin/tower -o start >> $HOME/.0L/logs/tower.log 2>&1 &
                                sleep 2
                                export DD=`pgrep tower`
                                if [ -n $DD ]
                                then
                                    echo -e "$TIME [INFO] ========= \e[1m\e[33m  Tower restarted.   \e[0m========="
                                fi
                            fi
                            R=15
                            sleep 1080
                        fi
                    fi
                done
            else
                sleep 430
            fi
        fi
    fi
done