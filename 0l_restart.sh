#!/bin/bash
PATH=$PATH:/home/node/bin
export TIME=`date +%Y-%m-%dT%I:%M:%S`
echo ""
echo "$TIME [INFO] Started."
J=1
K=10
while [ $J -lt $K ]
do
    export MIN=`date "+%M"`
    ACTION1=20
    if [ $MIN == $ACTION1 ]
    then
        export TIME=`date +%Y-%m-%dT%I:%M:%S`
        export syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\"} | grep -o '[0-9]*'`
        sleep 0.1
        if [ -z $syn1 ]
        then
            export syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
        fi
        export syn11=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
        sleep 0.1
        if [ -z $syn1 ]
        then
            echo "$TIME [ERROR] Unable to get network block height!! It looks like validator stopped!!"
            pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
            sleep 1
            BB=`pgrep diem-node`
            sleep 0.1
            if [ -z $BB ]
            then
                echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                rm -rf ~/.0L/db && pgrep diem-node || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                sleep 10
                nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                sleep 2
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                EE=`pgrep diem-node`
                if [ -z $EE ]
                then
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restore DB. You need to check node status manually. <<<\e[0m"
                else
                    echo "$TIME [INFO] Restored DB from network and restarted!"
                fi
            else
                echo -e "$TIME [INFO] \e[1m\e[32m========= Validator restarted! =========\e[0m"
            fi
        else
            echo "$TIME [INFO] Block height : $syn1"
            if [ -z $syn11 ]
            then
                export syn11=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
            else
                export LAG=`expr $syn11 - $syn1`
                if [ $LAG -gt -200 ]
                then
                    echo "$TIME [INFO] Synced height : $syn11, Fully synced."
                else
                    echo "$TIME [INFO] Synced height : $syn11, Lag : $LAG"
                fi
            fi
        fi
        sleep 1760
    fi
    export MIN=`date "+%M"`
    ACTION2=50
    if [ $MIN == $ACTION2 ]
    then
        export TIME=`date +%Y-%m-%dT%I:%M:%S`
        export syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\"} | grep -o '[0-9]*'`
        sleep 0.1
        if [ -z $syn2 ]
        then
            export syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
        fi
        export syn22=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
        sleep 0.1
        if [ -z $syn2 ]
        then
            echo "$TIME [ERROR] Unable to get network block height!! It looks like validator stopped!!"
            pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
            sleep 1
            BB=`pgrep diem-node`
            slepp 0.1
            export TIME=`date +%Y-%m-%dT%I:%M:%S`
            if [ -z $BB ]
            then
                echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                rm -rf ~/.0L/db && pgrep diem-node || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                sleep 10
                nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                sleep 2
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                EE=`pgrep diem-node`
                if [ -z $EE ]
                then
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restore DB. You need to check node status manually. <<<\e[0m"
                else
                    echo "$TIME [INFO] Restored DB from network and restarted!"
                fi
            else
                echo -e "$TIME [INFO] \e[1m\e[32m========= Validator restarted! =========\e[0m"
            fi
        else
            echo "$TIME [INFO] Block height : $syn2"
            if [ -z $syn22 ]
            then
                export syn22=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
            else
                export LAG=`expr $syn22 - $syn2`
                if [ $LAG -gt -200 ]
                then
                    echo "$TIME [INFO] Synced height : $syn22, Fully synced."
                else
                    echo "$TIME [INFO] Synced height : $syn22, Lag : $LAG"
                fi
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                if [ -z $syn11 ]
                then
                    echo "$TIME [INFO] No comparison data right now."
                else
                    if [ -z $syn1 ]
                    then
                        echo "$TIME [INFO] No comparison data right now."
                    else
                        NDIFF=`expr $syn2 - $syn1`
                        LDIFF=`expr $syn22 - $syn11`
                        NTPS=$(echo "scale=2; $NDIFF / 1800" | bc)
                        LTPS=$(echo "scale=2; $LDIFF / 1800" | bc)
                        SPEED=$(echo "scale=2; $NTPS - $LTPS" | bc)
                        if [ $SPEED == 0 ]
                        then
                            echo "$TIME [INFO] TPS >> Network : $NTPS[tx/s], Local : $LTPS[tx/s]"

                        else
                            echo "$TIME [INFO] TPS >> Network : $NTPS[tx/s], Local : $LTPS[tx/s]"
                            if [ $LAG -lt -200 ]
                            then
                                CATCH=$(echo "scale=2; ( $LAG / $SPEED ) / 3600" | bc)
                                echo -e "$TIME [INFO] Remained catchup time >> \e[1m\e[33m$CATCH\e[0m[Hr]"
                            fi
                        fi
                        SEEK1=`tail -4 ~/.0L/logs/tower.log |grep "Success: Proof committed to chain"`
                        if [ -z "$SEEK1" ]
                        then
                            echo -e "$TIME [WARN] \e[1m\e[35m>>> Tower failed to submitted a last proof! <<<\e[0m"
                            SEEK3=`tail -2 ~/.0L/logs/tower.log | sed -n 1p | grep -o '[0-9]*'`
                        else
                            SEEK2=`tail -2 ~/.0L/logs/tower.log | sed -n 1p | grep -o '[0-9]*'`
                            if [ -z "$SEEK3" ] ; then SEEK3=0 ; fi
                            CHECKTOWER=`expr $SEEK2 - $SEEK3`
                            if [ $CHECKTOWER -gt 0 ]
                            then
                                echo -e "$TIME [INFO] Tower is mining normally. \e[1m\e[32mProof # $SEEK2 \e[0m"
                            else
                                echo "$TIME [WARN] >>> Tower mining has been unsuccessful for at least an hour. <<<"
                            fi
                            SEEK3=`tail -2 ~/.0L/logs/tower.log | sed -n 1p | grep -o '[0-9]*'`
                        fi
                    fi
                fi
            fi
        fi
        sleep 560
    fi
    export MIN=`date "+%M"`
    ACTION3=59
    if [ $MIN == $ACTION3 ]
    then
        if [ -z $syn1 ] ; then syn1=0 ; fi
        if [ -z $syn2 ] ; then syn2=0 ; fi
        if [ $syn1 -eq $syn2 ]
        then
            PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null
            sleep 10
            export D=`pgrep diem-node`
            if [ -z $D ]
            then
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                echo "$TIME [INFO] Validator stopped for restarting!"
            fi
        else
            if [ $LAG -gt -5000 ]
            then
                CONVERT=`ps -ef|grep "diem-node --config /home/node/.0L/validator.node.yaml" | awk '/bin/{print $2}'`
                if [ -z $CONVERT ]
                then
                    PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null
                    sleep 10
                    export D=`pgrep diem-node`
                    if [ -z $D ]
                    then
                        export TIME=`date +%Y-%m-%dT%I:%M:%S`
                        echo "$TIME [INFO] Fullnode stopped for converting mode! Catchup completed."
                    fi
                fi
            fi
        fi
        sleep 40
    fi
    export MIN=`date "+%M"`
    ACTION4=00
    if [ $MIN == $ACTION4 ]
    then
        export LL=`pgrep diem-node`
        if [ -z $LL ]
        then
            if [ -z $LAG ] ; then LAG=-10000 ; fi
            if [ $LAG -gt -5000 ]
            then
                pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                sleep 5
                CC=`pgrep diem-node`
                if [ -z $CC ]
                then
                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                    rm -rf ~/.0L/db && pgrep diem-node > /dev/null || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                    sleep 10
                    nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 > /dev/null &
                    sleep 2
                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                    KK=`pgrep diem-node`
                    if [ -z $KK ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restore DB. You need to check node status manually. <<<\e[0m"
                    else
                        echo "$TIME [INFO] Restored DB from network and restarted!"
                    fi
                else
                    echo -e "$TIME [INFO] \e[1m\e[32m========= Validator restarted! Fully synced!! =========\e[0m"
                fi
            else
                pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/fullnode.node.yaml >> ~/.0L/logs/fullnode.log 2>&1 > /dev/null &
                sleep 5
                CC=`pgrep diem-node`
                if [ -z $CC ]
                then
                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                    rm -rf ~/.0L/db && pgrep diem-node > /dev/null || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                    sleep 10
                    nohup ~/bin/diem-node --config ~/.0L/fullnode.node.yaml >> ~/.0L/logs/fullnode.log 2>&1 > /dev/null &
                    sleep 2
                    export TIME=`date +%Y-%m-%dT%I:%M:%S`
                    KK=`pgrep diem-node`
                    if [ -z $KK ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restore DB. You need to check node status manually. <<<\e[0m"
                    else
                        echo "$TIME [INFO] Restored DB from network and restarted!"
                    fi
                else
                    echo -e "$TIME [INFO] ========= \e[1m\e[33mValidator restarted as fullnode mode. \e[0m========="
                fi
            fi
        else
            CONVERT=`ps -ef|grep "diem-node --config /home/node/.0L/fullnode.node.yaml" | awk '/bin/{print $2}'`
            if [ -z $CONVERT ]
            then
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                echo -e "$TIME [INFO] \e[1m\e[32m========= Validator running! =========\e[0m"
            else
                export TIME=`date +%Y-%m-%dT%I:%M:%S`
                echo -e "$TIME [INFO] \e[1m\e[33m========= Validator running as fullnode mode now. =========\e[0m"
            fi
        fi
        sleep 1160
    fi
    export NN=`pgrep tower`
    sleep 0.1
    if [ -z $NN ]
    then
        export TIME=`date +%Y-%m-%dT%I:%M:%S`
        echo -e "$TIME [ERROR] \e[1m\e[35m>>> Tower disconnected!! <<<\e[0m"
        nohup ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1 &
        sleep 2
        export QQ=`pgrep tower`
        if [ -n $QQ ]
        then
            echo -e "$TIME [INFO] ========= \e[1m\e[33m  Tower restarted.   \e[0m========="
        fi
    fi
    sleep 5
done