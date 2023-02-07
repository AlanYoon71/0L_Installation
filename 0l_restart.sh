#!/bin/bash
J=1
K=10
while [ $J -lt $K ]
do
    sleep 60
    HOUR=$(date "+%H")
    MIN=$(date "+%M")
    if [ $MIN -lt 20 ]
    then
        echo "syn1=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:20 &&
        wait
        export syn20=$(echo $syn1 | grep -o '[0-9]*') &&
    else
        if [ $MIN -lt 50 ]
        then
            echo "syn2=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\")" | at $HOUR:50 &&
            wait
            export syn50=$(echo $syn2 | grep -o '[0-9]*') &&
            if [ $syn50 == $syn20 ]
            then
                echo "/usr/bin/killall diem-node" | at $HOUR:59 &&
                wait
                export UP=`expr $HOUR + 1`
                if [ $UP -gt 22 ]
                then
                    UP=0
                    echo "~/bin/diem-node --config ~/.0L/fullnode.node.yaml 2>&1 | multilog s50000000 n10 ~/.0L/logs/node" | at $UP:00 &&
                    wait
                else
                    echo "~/bin/diem-node --config ~/.0L/fullnode.node.yaml 2>&1 | multilog s50000000 n10 ~/.0L/logs/node" | at $UP:00 &&
                    wait
                fi
            fi
        fi
    fi
done