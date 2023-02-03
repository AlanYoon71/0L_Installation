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

tmux send-keys -t $session:$window 'cd && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && . ~/.bashrc && cargo install toml-cli && git clone https://github.com/OLSF/libra.git && cd /home/node/libra && make bins install' C-m
sleep 1

tmux send-keys -t $session:$window '\n
' C-m

C=1
D=10
while [ $C -lt $D ]
do
    if [ -f /home/node/bin/onboard ]
    then
        echo ""
        echo "0l Binary files compiled successfully!"
        echo ""
        C=15
    else
    sleep 60
    fi
done

tmux send-keys -t $session:$window 'cd /home/node/bin && ./ol serve --update && ./onboard keygen > keygen.txt && cat keygen.txt && MNEM=$(sed -n '11p' /home/node/bin/keygen.txt)' C-m
sleep 1

tmux send-keys -t $session:$window '/home/node/bin/ol init -a && cd $HOME/.0L && mkdir logs && /home/node/bin/onboard user' C-m
sleep 5

echo ""
echo -e "\e[1m\e[32m4. Preparing account and genesis proof.. \e[0m"
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
    if [ -f /home/node/.0L/0L.toml ]
    then
        if [ -f /home/node/.0L/account.json ]
        then
            if [ -f /home/node/.0L/vdf_proofs/proof_0.json ]
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

                tmux send-keys -t $session1:$window 'ulimit -n 100000 && /home/node/bin/ol restore && /home/node/bin/diem-node --config ~/.0L/fullnode.node.yaml' C-m
                sleep 60

                session2="waypoint"
                tmux new-session -d -s $session2
                window=0
                tmux rename-window -t $session2:$window 'waypoint'
                sleep 1

                tmux send-keys -t $session2:$window '/home/node/bin/ol --config /home/node/.0L/0L.toml query --epoch > /home/node/bin/waypoint.txt && STR=$(cat /home/node/bin/waypoint.txt) && echo "${STR:(-73)}" > /home/node/bin/waypoint.txt && WAY=$(cat /home/node/bin/waypoint.txt) && echo ${#WAY} > /home/node/bin/waylength.txt' C-m
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
                    if [[ -n `grep $W /home/node/bin/waylength.txt` ]]
                    then
                        echo "Lastest waypoint fetched successfully!"
                        echo ""

                        G=1
                        H=10
                        while [ $G -lt $H ]
                        do
                            sleep 60
                            if [ -f /home/node/.0L/key_store.json ]
                            then
                                tmux send-keys -t $session2:$window 'sed -i'' -r -e "/tx_configs.baseline_cost/i\base_waypoint = \"$WAY\"" /home/node/.0L/0L.toml' C-m
                                sleep 5
                                tmux send-keys -t $session2:$window 'sed -i "s/tx = 10000/tx = 20000/g" /home/node/.0L/0L.toml' C-m
                                sleep 3
                                tmux send-keys -t $session2:$window 'sed -i "s/tx = 1000/tx = 20000/g" /home/node/.0L/0L.toml' C-m
                                sleep 3
                                tmux send-keys -t $session2:$window 'grep $WAY /home/node/.0L/0L.toml > /home/node/bin/WAYPOINT.txt && WAY2=$(cat /home/node/bin/WAYPOINT.txt) && echo ${#WAY2} > /home/node/bin/WAYLENGTH.txt && sleep 2 && cmp -s /home/node/bin/waypoint.txt /home/node/bin/WAYPOINT.txt > /home/node/bin/update_check.txt' C-m
                                sleep 3

                                if [ -s /home/node/bin/update_check.txt ]
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

                                    tmux send-keys -t $session:$window 'ulimit -n 100000 && /home/node/bin/ol restore && sleep 3 && cd /home/node/.0L && /home/node/bin/diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1' C-m
                                    sleep 180

                                    session="node_log"
                                    tmux new-session -d -s $session
                                    window=0
                                    tmux rename-window -t $session:$window 'node_log'
                                    sleep 1

                                    tmux send-keys -t $session:$window 'tail -f ~/.0L/logs/node.log' C-m

                                    if [ -s /home/node/.0L/logs/node.log ]
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

                                        syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
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
                                            sleep 10
                                            syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
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
                                        export TP=$(echo "scale=3; $delt / ( 10 * $S )" | bc) &&
                                        #export delta=$((sync2 - sync1)) &&
                                        if [ $delt -gt 0 ]
                                        then
                                            echo ""
                                            echo "Network alive!"
                                            echo ""
                                        else
                                            echo ""
                                            echo ">>> Network highest version is not changed during 5 minutes.. Checking skipped. <<<"
                                        fi

                                        #export TPS=$(echo "scale=2; $delta / ( 10 * $S )" | bc) &&

                                        #syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                        sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
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
                                            sleep 10
                                            #syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                            sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
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
                                            echo "Your fullnode is syncing now!"
                                            echo ""
                                        else
                                            echo ""
                                            echo ">>> Fullnode synced version is not changed at all during 5 minutes.. It's critical! <<<"
                                            exit
                                        fi

                                        export TPS=$(echo "scale=3; $delta / ( 10 * $S )" | bc) &&
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

                                        tmux send-keys -t $session:$window 'MNEM=$(sed -n '11p' /home/node/bin/keygen.txt)' C-m
                                        sleep 1

                                        tmux send-keys -t $session:$window 'cat /home/node/bin/keygen.txt' C-m
                                        sleep 1

                                        tmux send-keys -t $session:$window 'export NODE_ENV=prod && /home/node/bin/tower start >> ~/.0L/logs/tower.log 2>&1' C-m
                                        sleep 5

                                        echo -e "Open a new terminal and change user [ \e[1m\e[32msudo su node\e[0m ], attach TMUX session [ \e[1m\e[32mtmux attach -t $session\e[0m ], 
                                        copy and paste your mnemonic"
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
                                        export PROOF=/home/node/.0L/logs/tower.log
                                        while [ $Y -lt $Z ]
                                        do
                                            sleep 15
                                            export SIZE=$(stat -c%s "$PROOF")                                            
                                            if [[ $SIZE -gt 800  ]]
                                            then
                                                echo "Tower mining started!"
                                                echo ""
                                                echo ""
                                                echo "Tower can start to submit proofs on chain after onboarded and fully synced."
                                                echo ""
                                                Y=15
                                            fi
                                        done
                                        session="monitor"
                                        tmux new-session -d -s $session
                                        window=0
                                        tmux rename-window -t $session:$window 'monitor'
                                        sleep 1

                                        tmux send-keys -t $session:$window 'tmux ls > /home/node/bin/tmux_status.txt' C-m
                                        sleep 1

                                        tmux send-keys -t $session:$window 'cd /home/node/libra && make web-files && /home/node/bin/ol serve -c' C-m

                                        echo ""
                                        echo "Monitor started!"
                                        echo ""
                                        echo ""
                                        echo -e "From now, you can monitor your node in browser by typing [ \e[1m\e[32mhttp://your_IP:3030 \e[0m]"
                                        echo ""
                                        AUTH=$(sed -n '7p' /home/node/bin/keygen.txt)
                                        echo ""
                                        echo "To run tower and mine successfully, you should be onboarded by anyone who can onboard you with a transaction below."
                                        echo -e "[ \e[1m\e[32mtxs create-account --authkey $AUTH --coins 1 \e[0m]"
                                        sleep 2

                                        echo ""
                                        echo ""
                                        echo -e "\e[1m\e[32m[ TMUX sessions ] \e[0m"
                                        echo "===================="
                                        cat -n /home/node/bin/tmux_status.txt
                                        echo "===================="
                                        echo ""
                                        cat /home/node/bin/keygen.txt
                                        sleep 1

                                        echo ""
                                        echo -e "\e[1m\e[32mScript for TMUX completed! Installation is successful! \e[0m"
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
