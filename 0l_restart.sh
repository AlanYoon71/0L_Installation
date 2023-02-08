#!/bin/bash
J=1
K=10
while [ $J -lt $K ]
do
    HOUR=$(date "+%H")
    MIN=$(date "+%M")
    if [ $MIN -gt 18 ]
    then
        if [ $MIN -lt 20 ]
        then
            echo "syn1=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:20 && export syn20=$(echo $syn1 | grep -o '[0-9]*') &&
            if [ -z $syn20 ] ; then syn20=0 ; fi
            sleep 1800
        else
            if [ $MIN -lt 50 ]
            then
                echo "syn2=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:50 && export syn50=$(echo $syn2 | grep -o '[0-9]*') &&
                if [ -z $syn50 ] ; then syn50=0 ; fi
                sleep 540
                if [ $syn50 == $syn20 ]
                then
                    echo "/usr/bin/killall diem-node" | at $HOUR:59 &> /dev/null ;
                    UP=$(expr $HOUR + 1)
                    sleep 60
                    if [ $UP -gt 22 ]
                    then
                        UP=0
                        pgrep diem-node || echo "~/bin/diem-node --config ~/.0L/fullnode.node.yaml 2>&1 | multilog s50000000 n10 ~/.0L/logs/node" | at $UP:00 &&
                        echo "========================================= \e[1m\e[33mRestarted!! \e[0m========================================="
                        echo "Network block height stuck at $syn50"
                        date
                        echo "========================================= \e[1m\e[33mRestarted!! \e[0m========================================="
                        sleep 1140
                    else
                        pgrep diem-node || echo "~/bin/diem-node --config ~/.0L/fullnode.node.yaml 2>&1 | multilog s50000000 n10 ~/.0L/logs/node" | at $UP:00 &&
                        echo "========================================= \e[1m\e[33mRestarted!! \e[0m========================================="
                        echo "Network block height stuck at $syn50"
                        date
                        echo "========================================= \e[1m\e[33mRestarted!! \e[0m========================================="
                        sleep 1140
                    fi
                fi
            fi
        fi
    else
        sleep 60
    fi
done