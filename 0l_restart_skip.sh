#!/bin/bash
PATH=$PATH:/home/node/bin
echo ""
echo "This script fetches data from network and compares the difference between the two numbers."
echo "The checkpoint times are [**:20] and [**:50], so run this script before [**:20]."
echo ""
echo "If you want to skip monitoring a specific time(only 1 Hr possible), enter the exact UTC time.(e.g. 09, 14 etc) Enter if you don't want to skip."
read skip1
if [ -z "$skip1" ]
then
    export skip=100
    echo ""
else
    export skip=`echo $skip1`
    echo ""
    echo "< Notice > $skip:00 ~ $skip:59 Script will be slept."
    echo ""
fi
export TIME=`date +%Y-%m-%dT%H:%M:%S`
echo "$TIME [INFO] [Restart Script] started."
J=1
K=10
while [ $J -lt $K ]
do
    export HR=`date "+%H"`
    if [ $HR == $skip ]
    then
        export TIME=`date +%Y-%m-%dT%H:%M:%S`
        echo "$TIME [INFO] $skip:00 ~ $skip:59 Script goes to sleep."
        sleep 3600
        export TIME=`date +%Y-%m-%dT%H:%M:%S`
        echo "$TIME [INFO] Script woke up and restarted."
        sleep 65
    else
        export s1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\"} | grep -o '[0-9]*'`
        if [ -z "$s1" ]
        then
            export s1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
        fi
        export c1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"committed\"} | grep -o '[0-9]*'`
        sleep 0.1
        if [ -z "$s1" ] ; then s1=0 ; fi
        if [ -z "$c1" ] ; then c1=1000000000000000 ; fi
        export EMERG=`expr $s1 - $c1`
        sleep 0.1
        t1=0
        if [ "$EMERG" -gt 500 ]
        then
            t1=1
            if [ "$EMERG" -gt 1000 ]
            then
                t1=2
            fi
        fi
        if [ $t1 -gt 1 ]
        then
            export TIME=`date +%Y-%m-%dT%H:%M:%S`
            echo -e "$TIME [ERROR] \e[1m\e[31mEMERGENCY! Sync operation suddenly stopped!! \e[0m"
            echo "$TIME [INFO] Block  height : $s1"
            echo -e "$TIME [INFO] Synced height : $c1, Lag : \e[1m\e[31m$EMERG\e[0m"
            sleep 0.1
            PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null
            sleep 10
            export D=`pgrep diem-node`
            if [ -z "$D" ]
            then
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                echo "$TIME [INFO] Validator stopped for restarting!"
                pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                sleep 5
                CC=`pgrep diem-node`
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                if [ -z "$CC" ]
                then
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                    rm -rf ~/.0L/db && pgrep diem-node > /dev/null || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                    sleep 10
                    nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                    sleep 2
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    KK=`pgrep diem-node`
                    if [ -z "$KK" ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35mFailed to restore DB. You need to check node status manually.\e[0m"
                    else
                        echo -e "$TIME [INFO] \e[1m\e[32m========= Restored DB from network and restarted successfully! =========\e[0m"
                    fi
                else
                    echo -e "$TIME [INFO] \e[1m\e[32m======= Validator restarted successfully!! =======\e[0m"
                fi
            fi
        fi
        export MIN=`date "+%M"`
        ACTION1=20
        if [ $MIN == $ACTION1 ]
        then
            export EPOCH1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_state_sync_epoch" | grep -o '[0-9]*'`
            export TIME=`date +%Y-%m-%dT%H:%M:%S`
            export syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\"} | grep -o '[0-9]*'`
            export round1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_consensus_current_round" | grep -o '[0-9]*'`
            sleep 1
            export EPOCH1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_state_sync_epoch" | grep -o '[0-9]*'`
            sleep 0.2
            if [ -z "$EPOCH1" ] ; then EPOCH1=0 ; fi
            if [ -z "$EPOCH3" ] ; then EPOCH3=0 ; fi
            if [ "$EPOCH3" -gt 1 ]
            then
                if [ "$EPOCH1" -gt "$EPOCH3" ]
                then
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    echo -e "$TIME [INFO] ========= State sync epoch jumped to \e[1m\e[32m$EPOCH1 \e[0m========="
                    round2=0
                fi
            fi
            notvoting=`timeout 8s tail -f ~/.0L/logs/node/current | grep "currently not connected"`
            sleep 0.1
            export TIME=`date +%Y-%m-%dT%H:%M:%S`
            if [ -z "$notvoting" ]
            then
                echo -e "$TIME [INFO] \e[1m\e[32mAll addresses in active set are voting now. Great!\e[0m"
            else
                echo -e "$TIME [WARN] Current ConsensusDirectSend_Message \e[1m\e[31mUnresponsive(Not voting) \e[0mAddresses"
                echo -e "\e[1m\e[31m========\e[0m"
                echo "$notvoting" | grep -Po 'Peer [^,]+' | cut -d' ' -f2 | sort -u
                echo -e "\e[1m\e[31m========\e[0m"
            fi
            if [ -z "$round1" ] ; then round1=10000000000 ; fi
            if [ -z "$round2" ] ; then round2=0 ; fi
            sleep 0.1
            if [ "$round1" -lt "$round2" ] ; then round2=0 ; fi
            RD=`expr $round1 - $round2`
            if [ "$RD" -lt 1 ]
            then
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                echo -e "$TIME [ERROR] \e[1m\e[35mConsensus stopped at $round1 round!\e[0m"
                # PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null
                # sleep 10
                # export D=`pgrep diem-node`
                # if [ -z "$D" ]
                # then
                #     export TIME=`date +%Y-%m-%dT%H:%M:%S`
                #     echo "$TIME [INFO] Validator stopped for restarting!"
                #     pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                #     sleep 5
                #     CC=`pgrep diem-node`
                #     export TIME=`date +%Y-%m-%dT%H:%M:%S`
                #     if [ -z "$CC" ]
                #     then
                #         echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                #         rm -rf ~/.0L/db && pgrep diem-node > /dev/null || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                #         sleep 10
                #         nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                #         sleep 2
                #         export TIME=`date +%Y-%m-%dT%H:%M:%S`
                #         KK=`pgrep diem-node`
                #         if [ -z "$KK" ]
                #         then
                #             echo -e "$TIME [ERROR] \e[1m\e[35mFailed to restore DB. You need to check node status manually.\e[0m"
                #         else
                #             echo -e "$TIME [INFO] \e[1m\e[32m========= Restored DB from network and restarted successfully! =========\e[0m"
                #         fi
                #     else
                #         echo -e "$TIME [INFO] \e[1m\e[32m======= Validator restarted successfully!! =======\e[0m"
                #     fi
                # fi
            fi
            if [ -z "$syn1" ]
            then
                export syn1=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
            fi
            export syn11=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
            sleep 1
            if [ "$round1" -gt 0 ]
            then
                if [ -z "$syn1" ]
                then
                    echo "$TIME [WARN] >>> Validator already stopped!! <<<"
                    pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                    sleep 1
                    BB=`pgrep diem-node`
                    sleep 0.1
                    if [ -z "$BB" ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                        rm -rf ~/.0L/db && pgrep diem-node || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                        sleep 10
                        nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                        sleep 2
                        export TIME=`date +%Y-%m-%dT%H:%M:%S`
                        EE=`pgrep diem-node`
                        if [ -z "$EE" ]
                        then
                            echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restore DB. You need to check node status manually. <<<\e[0m"
                        else
                            echo -e "$TIME [INFO] \e[1m\e[32m========= Restored DB from network and restarted! =========\e[0m"
                        fi
                    else
                        echo -e "$TIME [INFO] \e[1m\e[32m========= Validator restarted!! =========\e[0m"
                    fi
                else
                    echo "$TIME [INFO] Block  height : $syn1, Consensus round : $round1"
                    if [ -z "$syn11" ]
                    then
                        export syn11=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
                    else
                        export LAG=`expr $syn11 - $syn1`
                        if [ "$LAG" -gt -200 ]
                        then
                            echo "$TIME [INFO] Synced height : $syn11, Fully synced."
                        else
                            echo -e "$TIME [INFO] Synced height : $syn11, Lag : \e[1m\e[35m$LAG\e[0m"
                        fi
                    fi
                fi
            fi
            sleep 60
        fi
        export MIN=`date "+%M"`
        ACTION2=50
        if [ $MIN == $ACTION2 ]
        then
            if [ -z "$syn1" ] ; then syn1=0 ; fi
            if [ -z "$syn11" ] ; then syn11=0 ; fi
            export TIME=`date +%Y-%m-%dT%H:%M:%S`
            export syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\"} | grep -o '[0-9]*'`
            export round2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_consensus_current_round" | grep -o '[0-9]*'`
            sleep 1
            export EPOCH2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_state_sync_epoch" | grep -o '[0-9]*'`
            sleep 0.2
            if [ -z "$EPOCH1" ] ; then EPOCH1=0 ; fi
            if [ -z "$EPOCH2" ] ; then EPOCH2=0 ; fi
            if [ "$EPOCH1" -gt 1 ]
            then
                if [ "$EPOCH2" -gt "$EPOCH1" ]
                then
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    echo -e "$TIME [INFO] ========= State sync epoch jumped to \e[1m\e[32m$EPOCH2 \e[0m========="
                fi
            fi
            sleep 0.2
            if [ -z "$round1" ] ; then round1=0 ; fi
            if [ -z "$round2" ] ; then round2=10000000000 ; fi
            sleep 0.1
            if [ -z "$syn2" ]
            then
                export syn2=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"} | grep -o '[0-9]*'`
            fi
            export syn22=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
            sleep 1
            if [ "$round2" -gt 0 ]
            then
                if [ -z "$syn2" ]
                then
                    echo "$TIME [WARN] >>> Validator already stopped!! <<<"
                    pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                    sleep 1
                    BB=`pgrep diem-node`
                    sleep 0.1
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    if [ -z "$BB" ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                        rm -rf ~/.0L/db && pgrep diem-node || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                        sleep 10
                        nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                        sleep 2
                        export TIME=`date +%Y-%m-%dT%H:%M:%S`
                        EE=`pgrep diem-node`
                        if [ -z "$EE" ]
                        then
                            echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restore DB. You need to check node status manually. <<<\e[0m"
                        else
                            echo -e "$TIME [INFO] \e[1m\e[32m========= Restored DB from network and restarted! =========\e[0m"
                        fi
                    else
                        echo -e "$TIME [INFO] \e[1m\e[32m========= Validator restarted!! =========\e[0m"
                    fi
                else
                    echo "$TIME [INFO] Block  height : $syn2, Consensus round : $round2"
                    if [ -z "$syn22" ]
                    then
                        export syn22=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
                    else
                        export LAG=`expr $syn22 - $syn2`
                        if [ "$LAG" -gt -200 ]
                        then
                            echo "$TIME [INFO] Synced height : $syn22, Fully synced."
                        else
                            echo -e "$TIME [INFO] Synced height : $syn22, Lag : \e[1m\e[35m$LAG\e[0m"
                        fi
                        export TIME=`date +%Y-%m-%dT%H:%M:%S`
                        if [ -z "$syn11" ]
                        then
                            echo "$TIME [INFO] No comparison data right now."
                        else
                            if [ -z "$syn1" ]
                            then
                                echo "$TIME [INFO] No comparison data right now."
                            else
                                export NDIFF=`expr $syn2 - $syn1`
                                export LDIFF=`expr $syn22 - $syn11`
                                export NTPS=$(echo "scale=2; $NDIFF / 1800" | bc)
                                sleep 0.2
                                export LTPS=$(echo "scale=2; $LDIFF / 1800" | bc)
                                sleep 0.2
                                export SPEED=$(echo "scale=2; $NTPS - $LTPS" | bc)
                                export EPOCH=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_state_sync_epoch" | grep -o '[0-9]*'`
                                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                                if [ "$SPEED" == 0 ]
                                then
                                    echo "$TIME [INFO] Sync    epoch : $EPOCH"
                                    echo "$TIME [INFO] Network   TPS : $NTPS[tx/s]"
                                    echo "$TIME [INFO] Local     TPS : $LTPS[tx/s]"
                                    if [ "$NDIFF" == 0 ] ; then echo "$TIME [WARN] Network transaction is very slow now." ; fi
                                else
                                    if [ -z "$syn1" ]
                                    then
                                        echo "$TIME [INFO] No comparison data right now."
                                    else
                                        echo "$TIME [INFO] Sync    epoch : $EPOCH"
                                        echo "$TIME [INFO] Network   TPS : $NTPS[tx/s]"
                                        echo "$TIME [INFO] Local     TPS : $LTPS[tx/s]"
                                        if [ "$LDIFF" -lt 500 ]
                                        then
                                            echo -e "$TIME [WARN] \e[1m\e[35m>>> Local speed is too slow to sync!! <<<\e[0m"
                                            echo -e "$TIME [WARN] \e[1m\e[35m>>> Validator needs to be restarted to recover syncing speed. <<<\e[0m"
                                        else
                                            if [ "$LDIFF" -gt "$NDIFF" ]
                                            then
                                                if [ "$LAG" -lt -500 ]
                                                then
                                                    export CATCH=$(echo "scale=2; ( $LAG / $SPEED ) / 3600" | bc)
                                                    echo -e "$TIME [INFO] Remained catchup time : \e[1m\e[35m$CATCH\e[0m[Hr]"
                                                fi
                                            fi
                                        fi
                                    fi
                                fi
                                SEEK1=`tail -4 ~/.0L/logs/tower.log |grep "Success: Proof committed to chain"`
                                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                                if [ -z "$SEEK1" ]
                                then
                                    echo -e "$TIME [ERROR] \e[1m\e[35mTower failed to submit a last proof! \e[0m"
                                    SEEK3=`tail -2 ~/.0L/logs/tower.log | sed -n 1p | grep -o '[0-9]*'`
                                else
                                    SEEK2=`tail -2 ~/.0L/logs/tower.log | sed -n 1p | grep -o '[0-9]*'`
                                    if [ -z "$SEEK2" ] ; then SEEK2=0 ; fi
                                    if [ -z "$SEEK3" ] ; then SEEK3=0 ; fi
                                    CHECKTOWER=`expr $SEEK2 - $SEEK3`
                                    if [ "$CHECKTOWER" -gt 0 ]
                                    then
                                        echo -e "$TIME [INFO] Tower is mining normally. \e[1m\e[32mProof # $SEEK2 \e[0m"
                                    else
                                        echo -e "$TIME [ERROR] \e[1m\e[35mTower mining has been unsuccessful for at least an hour.\e[0m"
                                    fi
                                    SEEK3=`tail -2 ~/.0L/logs/tower.log | sed -n 1p | grep -o '[0-9]*'`
                                fi
                            fi
                        fi
                    fi
                fi
            fi
            sleep 60
        fi
        export MIN=`date "+%M"`
        ACTION3=59
        if [ $MIN == $ACTION3 ]
        then
            if [ -z "$round1" ] ; then round1=0 ; fi
            if [ -z "$round2" ] ; then round2=10000000000 ; fi
            sleep 0.1
            if [ "$round2" -lt "$round1" ] ; then round1=0 ; fi
            RD=`expr $round2 - $round1`
            sleep 0.2
            if [ "$RD" -lt 1 ]
            then
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                echo -e "$TIME [ERROR] \e[1m\e[35mConsensus stopped at $round2 round!\e[0m"
                # timeout 8s tail -f ~/.0L/logs/node/current | grep "currently not connected" > ConsensusDirectSend_NG.txt
                # sleep 0.1
                # check=`cat ConsensusDirectSend_NG.txt`
                # if [ -z "$check" ]
                # then
                #     export TIME=`date +%Y-%m-%dT%H:%M:%S`
                #     echo -e "$TIME [INFO] All addresses in active set are voting now. Great!"
                # else
                #     echo -e "Current ConsensusDirectSend_Message \e[1m\e[31mUnresponsive \e[0mAddresses"
                #     echo -e "\e[1m\e[31m========\e[0m"
                #     cat ConsensusDirectSend_NG.txt | grep -Po 'Peer [^,]+' | cut -d' ' -f2 | sort -u
                #     echo -e "\e[1m\e[31m========\e[0m"
                # fi
                PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(pgrep diem-node) && kill -TERM $PID &> /dev/null
                sleep 10
                export D=`pgrep diem-node`
                if [ -z "$D" ]
                then
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    echo "$TIME [INFO] Validator stopped for restarting!"
                fi
            else
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                export round3=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_consensus_current_round" | grep -o '[0-9]*'`
                echo -e "$TIME [INFO] Consensus is in progress. \e[1m\e[32mCurrent round : $round3 \e[0m"
            fi
            sleep 40
        fi
        export MIN=`date "+%M"`
        ACTION4=00
        if [ $MIN == $ACTION4 ]
        then
            export EPOCH3=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_state_sync_epoch" | grep -o '[0-9]*'`
            sleep 0.2
            if [ -z "$EPOCH2" ] ; then EPOCH2=0 ; fi
            if [ -z "$EPOCH3" ] ; then EPOCH3=0 ; fi
            if [ "$EPOCH2" -gt 1 ]
            then
                if [ "$EPOCH3" -gt "$EPOCH2" ]
                then
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    echo -e "$TIME [INFO] ========= State sync epoch jumped to \e[1m\e[32m$EPOCH3 \e[0m========="
                fi
            fi
            sleep 0.2
            export LL=`pgrep diem-node`
            if [ -z "$LL" ]
            then
                pgrep diem-node || nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                sleep 5
                CC=`pgrep diem-node`
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                if [ -z "$CC" ]
                then
                    echo -e "$TIME [ERROR] \e[1m\e[35m>>> Failed to restart.. Trying to restore DB now. <<<\e[0m"
                    rm -rf ~/.0L/db && pgrep diem-node > /dev/null || ~/bin/ol restore >> ~/.0L/logs/restore.log 2>&1 > /dev/null &
                    sleep 10
                    nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node > /dev/null &
                    sleep 2
                    export TIME=`date +%Y-%m-%dT%H:%M:%S`
                    KK=`pgrep diem-node`
                    if [ -z "$KK" ]
                    then
                        echo -e "$TIME [ERROR] \e[1m\e[35mFailed to restore DB. You need to check node status manually.\e[0m"
                    else
                        echo -e "$TIME [INFO] \e[1m\e[32m========= Restored DB from network and restarted successfully! =========\e[0m"
                    fi
                else
                    echo -e "$TIME [INFO] \e[1m\e[32m======= Validator restarted successfully!! =======\e[0m"
                fi
            else
                CONVERT=`ps -ef|grep "diem-node --config /home/node/.0L/fullnode.node.yaml" | awk '/bin/{print $2}'`
                export TIME=`date +%Y-%m-%dT%H:%M:%S`
                if [ -z "$CONVERT" ]
                then
                    echo "$TIME [INFO] ========= Validator is running well now. ========="
                fi
            fi
            sleep 60
        fi
        export NN=`pgrep tower`
        sleep 0.2
        if [ -z "$NN" ]
        then
            export TIME=`date +%Y-%m-%dT%H:%M:%S`
            echo -e "$TIME [ERROR] \e[1m\e[35m>>> Tower disconnected!! <<<\e[0m"
            nohup ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1 &
            sleep 2
            export QQ=`pgrep tower`
            if [ -n "$QQ" ]
            then
                echo -e "$TIME [INFO] \e[1m\e[33m=========   Tower restarted successfully!!   =========\e[0m"
            fi
        fi
        sleep 20
    fi
done