#!/bin/bash
killall diem-node &> /dev/null ;
sleep 3

session="onboarding"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'onboarding'
sleep 1

echo ""
echo "Script for TMUX background started."
echo ""
sleep 1

tmux send-keys -t $session:$window 'cd && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && . ~/.bashrc && cargo install toml-cli && git clone https://github.com/OLSF/libra.git && cd $HOME/libra && make bins install' C-m
sleep 1

tmux send-keys -t $session:$window '\n
' C-m

C=1
D=10
while [ $C -lt $D ]
do
    if [ -f $HOME/bin/onboard ]
    then
        echo ""
        echo "0l Binary files compiled successfully!"
        echo ""
        C=15
    else
    sleep 60
    fi
done

tmux send-keys -t $session:$window 'cd $HOME/bin && ./ol serve --update && ./onboard keygen > keygen.txt && cat keygen.txt && MNEM=$(sed -n '11p' $HOME/bin/keygen.txt)' C-m
sleep 1

tmux send-keys -t $session:$window '$HOME/bin/ol init -a && cd $HOME/.0L && mkdir logs && $HOME/bin/onboard user' C-m
sleep 5

echo ""
echo -e "\e[1m\e[32m4. Creating account and genesis proof.. \e[0m"
echo "===================="
echo ""
echo -e "Open a new terminal and change user to \"node\" [ \e[1m\e[32msudo su node\e[0m ], attach TMUX session [ \e[1m\e[32mtmux attach -t $session\e[0m ], 
copy and paste your mnemonic and answer questions for basic configuration."
echo ""
echo ""
echo "And then just wait until your first mining is completed. This mining takes 20 ~ 40min, up to server's CPU performance."
echo ""

A=1
B=10
while [ $A -lt $B ]
do
    sleep 60
    if [ -f $HOME/.0L/0L.toml ]
    then
        if [ -f $HOME/.0L/account.json ]
        then
            if [ -f $HOME/.0L/vdf_proofs/proof_0.json ]
            then
                echo ""
                echo "Account and genesis proof created successfully!"
                echo ""
                echo ""
                echo "Your account is on local fullnode now and will not be found on chain until onboarded and fully synced."
                sleep 3

                tmux kill-session -t $session
                sleep 3

                session1="restore"
                tmux new-session -d -s $session1
                window=0
                tmux rename-window -t $session1:$window 'restore'
                sleep 1

                tmux send-keys -t $session1:$window 'ulimit -n 100000 && $HOME/bin/ol restore && $HOME/bin/diem-node --config ~/.0L/fullnode.node.yaml' C-m
                sleep 60

                session2="waypoint"
                tmux new-session -d -s $session2
                window=0
                tmux rename-window -t $session2:$window 'waypoint'
                sleep 1

                tmux send-keys -t $session2:$window '$HOME/bin/ol --config $HOME/.0L/0L.toml query --epoch > $HOME/bin/waypoint.txt && STR=$(cat $HOME/bin/waypoint.txt) && echo "${STR:(-73)}" > $HOME/bin/waypoint.txt && WAY=$(cat $HOME/bin/waypoint.txt) && echo ${#WAY} > $HOME/bin/waylength.txt' C-m
                sleep 10

                echo ""
                echo -e "\e[1m\e[32m5. Updating fullnode configurations.. \e[0m"
                echo "===================="
                echo ""

                E=1
                F=10
                while [ $E -lt $F ]
                do
                    sleep 60
                    W=73
                    if [[ -n `grep $W $HOME/bin/waylength.txt` ]]
                    then
                        echo "Lastest waypoint fetched successfully!"
                        echo ""

                        G=1
                        H=10
                        while [ $G -lt $H ]
                        do
                            sleep 60
                            if [ -f $HOME/.0L/key_store.json ]
                            then
                                tmux send-keys -t $session2:$window 'sed -i'' -r -e "/tx_configs.baseline_cost/i\base_waypoint = \"$WAY\"" $HOME/.0L/0L.toml' C-m
                                sleep 5
                                tmux send-keys -t $session2:$window 'sed -i "s/tx = 10000/tx = 20000/g" $HOME/.0L/0L.toml' C-m
                                sleep 3
                                tmux send-keys -t $session2:$window 'sed -i "s/tx = 1000/tx = 20000/g" $HOME/.0L/0L.toml' C-m
                                sleep 3
                                tmux send-keys -t $session2:$window 'grep $WAY $HOME/.0L/0L.toml > $HOME/bin/WAYPOINT.txt && WAY2=$(cat $HOME/bin/WAYPOINT.txt) && echo ${#WAY2} > $HOME/bin/WAYLENGTH.txt && sleep 2 && cmp -s $HOME/bin/waypoint.txt $HOME/bin/WAYPOINT.txt > $HOME/bin/update_check.txt' C-m
                                sleep 3

                                if [ -s $HOME/bin/update_check.txt ]
                                then
                                    echo ""
                                    echo ">>> Configuration update failed... <<<"
                                    exit
                                else
                                    echo ""
                                    echo "Fullnode configuration updated!"
                                    echo ""

                                    tmux kill-session -t $session1 &&
                                    sleep 2
                                    tmux kill-session -t $session2 &&
                                    sleep 2

                                    echo ""
                                    echo -e "\e[1m\e[32m6. Starting fullnode.. \e[0m"
                                    echo "===================="
                                    echo ""

                                    session="fullnode"
                                    tmux new-session -d -s $session
                                    window=0
                                    tmux rename-window -t $session:$window 'fullnode'
                                    sleep 1

                                    tmux send-keys -t $session:$window 'ulimit -n 100000 && $HOME/bin/ol restore && sleep 3 && cd $HOME/.0L && $HOME/bin/diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1' C-m
                                    sleep 180

                                    session="fullnode_log"
                                    tmux new-session -d -s $session
                                    window=0
                                    tmux rename-window -t $session:$window 'fullnode_log'
                                    sleep 1

                                    tmux send-keys -t $session:$window 'tail -f ~/.0L/logs/node.log' C-m

                                    if [ -s $HOME/.0L/logs/node.log ]
                                    then
                                        echo "Fullnode started!"
                                        echo ""
                                        sleep 2

                                        echo ""
                                        echo -e "\e[1m\e[32m7. Checking sync status.. \e[0m"
                                        echo "===================="
                                        echo ""
                                        echo "Waiting fullnode is stabled and start syncing.. Be patient, please."
                                        echo ""
                                        sleep 300

                                        export syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                        #sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                        echo $syn &&
                                        #echo $sync &&
                                        export syn1=$(echo $syn | grep -o '[0-9]*') &&
                                        #export sync1=$(echo $sync | grep -o '[0-9]*') &&
                                        echo ""
                                        echo "Checking highest versions until figures increase.." &&
                                        echo ""
                                        S=1
                                        SS=30
                                        while [ $S -lt $SS ]
                                        do
                                            sleep 30
                                            export syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                            #sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                            echo $syn &&
                                            #echo $sync &&
                                            export syn2=$(echo $syn | grep -o '[0-9]*') &&
                                            #export sync2=$(echo $sync | grep -o '[0-9]*') &&
                                            if [ $syn2 == $syn1 ]
                                            then
                                                export S=`expr $S + 1`
                                            else
                                                SS=1
                                            fi
                                        done

                                        export delt=$((syn2 - syn1)) &&
                                        export TP=$(echo "scale=3; $delt / ( 30 * $S )" | bc) &&
                                        #export delta=$((sync2 - sync1)) &&
                                        if [ $delt -gt 0 ]
                                        then
                                            echo ""
                                            echo -e "\e[1m\e[32mNetwork alive! \e[0m"
                                            echo ""
                                            echo ""
                                        else
                                            echo ""
                                            echo ">>> Network highest version is not changed during 5 minutes.. Checking skipped. <<<"
                                        fi

                                        #export TPS=$(echo "scale=2; $delta / ( 10 * $S )" | bc) &&

                                        #syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                        export sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                        #echo $syn &&
                                        echo $sync &&
                                        #export syn1=$(echo $syn | grep -o '[0-9]*') &&
                                        export sync1=$(echo $sync | grep -o '[0-9]*') &&
                                        echo ""
                                        echo "Checking synced versions until figures increase.." &&
                                        echo ""

                                        S=1
                                        SS=30
                                        while [ $S -lt $SS ]
                                        do
                                            sleep 30
                                            #syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                            export sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                            #echo $syn &&
                                            echo $sync &&
                                            #export syn2=$(echo $syn | grep -o '[0-9]*') &&
                                            export sync2=$(echo $sync | grep -o '[0-9]*') &&
                                            if [ $sync2 == $sync1 ]
                                            then
                                                export S=`expr $S + 1`
                                            else
                                                SS=1
                                            fi
                                        done

                                        #export delt=$((syn2 - syn1)) &&
                                        #export TP=$(echo "scale=2; $delt / ( 10 * $S )" | bc) &&
                                        export delta=$((sync2 - sync1)) &&
                                        if [ $delta -gt 0 ]
                                        then
                                            echo ""
                                            echo -e "\e[1m\e[32mYour fullnode is syncing now! \e[0m"
                                            echo ""
                                        else
                                            echo ""
                                            echo ">>> Fullnode synced version is not changed at all during 5 minutes.. It's critical! <<<"
                                            exit
                                        fi

                                        export TPS=$(echo "scale=3; $delta / ( 30 * $S )" | bc) &&
                                        export SPEED=$(echo "scale=3; $TPS - $TP" | bc) &> /dev/null &&
                                        echo ""
                                        echo "===================="
                                        echo -e "Network TPS : \e[1m\e[32m$TP \e[0m[tx/s]"
                                        echo -e "Local   TPS : \e[1m\e[32m$TPS \e[0m[tx/s]"
                                        echo "===================="
                                        echo ""
                                        if [[ `echo "$SPEED > 0" | bc` -eq 0 ]]
                                        then
                                            echo ">>> Fullnode is syncing but too slow to catch up, so you need to restore and restarted manually later! <<<"
                                            echo ""
                                        fi

                                        export highest=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                        export synced=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                        sleep 1
                                        export highest1=$(echo $highest | grep -o '[0-9]*') &&
                                        export synced1=$(echo $synced | grep -o '[0-9]*') &&
                                        sleep 1
                                        export LAG=$((highest1 - synced1)) &&
                                        export CATCH=$(echo "scale=3; ( $LAG / $SPEED ) / 3600" | bc) &&

                                        echo "===================="
                                        echo -e "Syncing Lag     (current) : \e[1m\e[35m$LAG \e[0m"
                                        echo -e "Catch Up Time (estimated) : \e[1m\e[35m$CATCH \e[0m[Hr]"
                                        echo "===================="
                                        echo ""
                                        echo ""
                                        echo -e "\e[1m\e[32m8. Starting tower and monitor.. \e[0m"
                                        echo "===================="
                                        echo ""

                                        session="tower"
                                        tmux new-session -d -s $session
                                        window=0
                                        tmux rename-window -t $session:$window 'tower'
                                        sleep 1

                                        tmux send-keys -t $session:$window 'MNEM=$(sed -n '11p' $HOME/bin/keygen.txt)' C-m
                                        sleep 1

                                        tmux send-keys -t $session:$window 'cat $HOME/bin/keygen.txt' C-m
                                        sleep 1

                                        tmux send-keys -t $session:$window 'export NODE_ENV=prod && $HOME/bin/tower start >> ~/.0L/logs/tower.log 2>&1' C-m
                                        sleep 5

                                        echo -e "Open a new terminal and change user [ \e[1m\e[32msudo su node\e[0m ], attach TMUX session [ \e[1m\e[32mtmux attach -t $session\e[0m ], copy and paste your mnemonic"
                                        echo ""
                                        echo ""
                                        sleep 30

                                        session="tower_log"
                                        tmux new-session -d -s $session
                                        window=0
                                        tmux rename-window -t $session:$window 'tower_log'
                                        sleep 1

                                        tmux send-keys -t $session:$window 'tail -f ~/.0L/logs/tower.log' C-m
                                        
                                        Y=1
                                        Z=10
                                        export PROOF=$HOME/.0L/logs/tower.log
                                        while [ $Y -lt $Z ]
                                        do
                                            sleep 15
                                            export SIZE=$(stat -c%s "$PROOF")                                            
                                            if [[ $SIZE -gt 800  ]]
                                            then
                                                echo "Tower started!"
                                                echo ""
                                                echo ""
                                                echo "Tower can start to submit proofs on chain only after onboarded and fully synced. After fully synced, you need to restart tower."
                                                echo ""
                                                sleep 2
                                                echo "Even if tower fails to start now, the tower can be started after syncing is finished. Don't worry."
                                                echo ""
                                                Y=15
                                            fi
                                        done
                                        session="monitor"
                                        tmux new-session -d -s $session
                                        window=0
                                        tmux rename-window -t $session:$window 'monitor'
                                        sleep 1

                                        tmux send-keys -t $session:$window 'tmux ls > $HOME/bin/tmux_status.txt' C-m
                                        sleep 1

                                        tmux send-keys -t $session:$window 'cd $HOME/libra && make web-files && $HOME/bin/ol serve -c' C-m

                                        echo ""
                                        echo "Monitor started!"
                                        echo ""
                                        echo ""
                                        echo -e "From now, you can monitor your node in browser by typing [ \e[1m\e[32mhttp://your_IP:3030 \e[0m]"
                                        echo ""
                                        AUTH=$(sed -n '7p' $HOME/bin/keygen.txt)
                                        echo ""
                                        echo "To run tower and mine successfully, you should be onboarded by anyone who can onboard you with a transaction below."
                                        echo -e "[ \e[1m\e[32mtxs create-account --authkey $AUTH --coins 1 \e[0m]"
                                        sleep 2

                                        echo ""
                                        echo ""
                                        echo -e "\e[1m\e[32m[ TMUX sessions ] \e[0m"
                                        echo "===================="
                                        cat -n $HOME/bin/tmux_status.txt
                                        echo "===================="
                                        echo ""
                                        cat $HOME/bin/keygen.txt
                                        sleep 1

                                        echo ""
                                        echo "Script for TMUX completed! Installation is successful!"
                                        echo ""
                                        A=15
                                        E=15
                                        G=15
                                    else
                                        echo ""
                                        echo ">>> Fullnode failed to start... It's critical! <<<"
                                        echo ""
                                        sleep 1
                                        echo ">>> Fullnode failed to start... It's critical! <<<"
                                        exit
                                    fi
                                fi
                            fi
                        done
                    fi
                done
            fi
        fi
    fi
done
