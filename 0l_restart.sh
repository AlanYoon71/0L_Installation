#!/bin/bash
echo ""
echo "==============================";
echo ""
echo "Created by  //-\ ][_ //-\ ][\[";
echo ""
echo "==============================";
echo "                    2023-02-12"
echo ""
echo "This script was created only for restarting \"0L network validator\"."
echo ""
echo ""
export TIME=`date +%Y-%m-%dT%I:%M:%S`
echo "$TIME [INFO] Started."
J=1
K=10
while [ $J -lt $K ]
do
    sleep 5
    export HOUR=`date "+%H"`
    export MIN=`date "+%M"`
    ACTION1=20
    if [ $MIN == $ACTION1 ]
    then
        export TIME=`date +%Y-%m-%dT%I:%M:%S`
        syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
        syn11=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
        if [ -z $syn1 ]
        then
            echo "$TIME [WARN] >>> Unable to get network block height!! <<<"
            echo "$TIME [WARN] Validator is already stopped before running this script."
            pgrep diem-node > /dev/null || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
            sleep 2
            syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
            BB=`pgrep diem-node`
            if [ -z $BB ]
            then
                echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Critical! <<<\e[0m"
                rm -rf ~/.0L/db && ~/bin/ol restore &
                sleep 10
                nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                sleep 2
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                EE=`pgrep diem-node`
                if [ -z $EE ]
                then
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Tried but failed to restore DB and restart.. You need to check validator manually. <<<\e[0m"
                else
                    echo -e "$TIME [INFO] \e[1m\e[32mRestored DB from network and restarted successfully! \e[0m"
                fi
            else
                echo -e "$TIME [INFO] ========= \e[1m\e[32mValidator restarted. \e[0m========="
            fi
        else
            echo "$TIME [INFO] Block height : $syn1"
            if [ -z $syn11 ]
            then
                echo "$TIME [WARN] Unable to get synced height!"
                syn11=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
            else
                LAG=`expr $syn11 - $syn1`
                if [ $LAG -gt -200 ]
                then
                    echo "$TIME [INFO] Synced height : $syn11, Lag : $LAG"
                else
                    echo -e "$TIME [INFO] Synced height : $syn11, Lag : \e[1m\e[35m$LAG\e[0m"
                fi
            fi
        fi
        sleep 1780
    else
        ACTION2=50
        if [ $MIN == $ACTION2 ]
        then
            export TIME=`date +%Y-%m-%dT%I:%M:%S`
            syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
            syn22=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
            if [ -z $syn2 ]
            then
                echo "$TIME [WARN] >>> Unable to get network block height!! <<<"
                echo "$TIME [WARN] Validator is already stopped before running this script."
                pgrep diem-node > /dev/null || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                sleep 2
                syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
                CC=`pgrep diem-node`
                if [ -z $CC ]
                then
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Critical! <<<\e[0m"
                    rm -rf ~/.0L/db && ~/bin/ol restore &
                    sleep 10
                    nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                    sleep 2
                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                    KK=`pgrep diem-node`
                    if [ -z $KK ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35m>>> Tried but failed to restore DB and restart.. You need to check validator manually. <<<\e[0m"
                    else
                        echo -e "$TIME [INFO] \e[1m\e[32mRestored DB from network and restarted successfully! \e[0m"
                    fi
                else
                    echo -e "$TIME [INFO] ========= \e[1m\e[32mValidator restarted. \e[0m========="
                fi
            else
                echo "$TIME [INFO] Block height : $syn2"
                if [ -z $syn22 ]
                then
                    echo "$TIME [WARN] Unable to get synced height!"
                    syn22=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
                else
                    LAG=`expr $syn22 - $syn2`
                    if [ $LAG -gt -200 ]
                    then
                        echo -e "$TIME [INFO] Synced height : $syn22, Lag : \e[1m\e[35mNo lag. Fully synced.\e[0m"
                    else
                        echo -e "$TIME [INFO] Synced height : $syn22, Lag : \e[1m\e[35m$LAG\e[0m"
                    fi
                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                    if [ -z $syn11 ]
                    then
                        echo "$TIME [INFO] Insufficient comparison data. Need to wait until next checkpoint."
                    else
                        if [ -z $syn1 ]
                        then
                            echo "$TIME [INFO] Insufficient comparison data. Need to wait until next checkpoint."
                        else
                            NDIFF=`expr $syn2 - $syn1`
                            LDIFF=`expr $syn22 - $syn11`
                            NTPS=$(echo "scale=2; $NDIFF / 1800" | bc)
                            LTPS=$(echo "scale=2; $LDIFF / 1800" | bc)
                            SPEED=$(echo "scale=2; $NTPS - $LTPS" | bc)
                            CATCH=$(echo "scale=2; ( $LAG / $SPEED ) / 3600" | bc)
                            echo -e "$TIME [INFO] TPS >> Network : $NTPS[tx/s], Local : \e[1m\e[32m$LTPS\e[0m[tx/s]"
                            echo -e "$TIME [INFO] Catchup Time >> \e[1m\e[35m$CATCH\e[0m[Hr]"
                        fi
                    fi
                fi
            fi
            if [ -z $syn1 ] ; then syn1=0 ; fi
            if [ -z $syn2 ] ; then syn2=0 ; fi
            export TIME=`date +%Y-%m-%dT%I:%M:%S`
            if [ $syn1 == $syn2 ]
            then
                if [ $syn2 == 0 ]
                then
                    echo "$TIME [WARN] >>> Unable to get network block height!! <<<"
                else
                    echo "$TIME [WARN] Block height stuck!! >> $syn2"
                fi
                sleep 430
                P=1
                PP=10
                while [ $P -lt $PP ]
                do
                    sleep 5
                    export MIN=`date "+%M"`
                    ACTION3=58
                    if [ $MIN == $ACTION3 ]
                    then
                        export TIME=`date +%Y-%m-%dT%I:%M:%S`
                        PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null
                        sleep 1
                        export D=`pgrep diem-node`
                        if [ -z $D ]
                        then
                            echo "$TIME [INFO] Validator stopped for restarting."
                            P=15
                        else
                            echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to stop diem-node... <<<\e[0m"
                            P=15
                        fi
                    fi
                done
                R=1
                RR=10
                while [ $R -lt $RR ]
                do
                    sleep 5
                    export MIN=`date "+%M"`
                    ACTION4=00
                    if [ $MIN == $ACTION4 ]
                    then
                        export D=`pgrep diem-node`
                        if [ -z $D ]
                        then
                            export TIME=`date +%Y-%m-%dT%I:%M:%S`
                            nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                            sleep 2
                            export D=`pgrep diem-node`
                            if [ -z $D ]
                            then
                                echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Critical! Check your validator manually!! <<<\e[0m"
                                R=15
                                sleep 1080
                            else
                                echo -e "$TIME [INFO] ========= \e[1m\e[32mValidator restarted. \e[0m========="
                                export DD=`pgrep tower`
                                if [ -z $DD ]
                                then
                                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                                    echo "$TIME [WARN] >>> Tower disconnected!! <<<"
                                    nohup ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1 &
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
                    fi
                done
            else
                sleep 430
            fi
        fi
    fi
done