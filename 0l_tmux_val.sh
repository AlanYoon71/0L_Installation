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

tmux send-keys -t $session:$window 'cd && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && . $HOME/.bashrc && cargo install toml-cli && git clone --branch v5.2.0 https://github.com/0LNetworkCommunity/libra.git && cd $HOME/libra && make bins install' C-m
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

PATH=$PATH:/home/node/bin &&
. $HOME/.bashrc &&

tmux send-keys -t $session:$window 'cd && PATH=$PATH:/home/node/bin && . $HOME/.bashrc && ol serve --update && onboard keygen > $HOME/bin/keygen.txt && cat $HOME/bin/keygen.txt && MNEM=$(sed -n '11p' $HOME/bin/keygen.txt)' C-m
sleep 1

tmux send-keys -t $session:$window 'cd $HOME/.0L && mkdir logs && onboard val' C-m
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
                echo "Your account is on local now and will not be found on chain until onboarded and fully synced."
                sleep 3

                tmux kill-session -t $session
                sleep 3

                session1="restore"
                tmux new-session -d -s $session1
                window=0
                tmux rename-window -t $session1:$window 'restore'
                sleep 1

                tmux send-keys -t $session1:$window 'ulimit -n 100000 && ol restore && diem-node --config $HOME/.0L/fullnode.node.yaml 2>&1 | multilog s104857600 n10 $HOME/.0L/logs/node' C-m
                sleep 60

                session2="waypoint"
                tmux new-session -d -s $session2
                window=0
                tmux rename-window -t $session2:$window 'waypoint'
                sleep 1

                tmux send-keys -t $session2:$window 'ol --config $HOME/.0L/0L.toml query --epoch > $HOME/bin/waypoint.txt && sleep 20 && STR=$(cat $HOME/bin/waypoint.txt) && echo "${STR:(-73)}" > $HOME/bin/waypoint.txt && WAY=$(cat $HOME/bin/waypoint.txt) && echo ${#WAY} > $HOME/bin/waylength.txt' C-m
                sleep 10

                echo ""
                echo ""
                echo -e "\e[1m\e[32m5. Updating validator configuration.. \e[0m"
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
                                    echo "Configuration updated!"
                                    echo ""

                                    tmux kill-session -t $session1 &&
                                    sleep 2
                                    tmux kill-session -t $session2 &&
                                    sleep 2

                                    echo ""
                                    echo -e "\e[1m\e[32m6. Starting validator.. \e[0m"
                                    echo "===================="
                                    echo ""

                                    session="validator"
                                    tmux new-session -d -s $session
                                    window=0
                                    tmux rename-window -t $session:$window 'validator'
                                    sleep 1

                                    tmux send-keys -t $session:$window 'ulimit -n 100000 && WAY=$(cat $HOME/bin/waypoint.txt) && rm -Rf $HOME/.0L/db && sleep 10 && $HOME/bin/ol restore && sleep 20 && $HOME/bin/ol init --key-store --waypoint $WAY && sleep 10 && cat $HOME/bin/keygen.txt && $HOME/bin/diem-node --config $HOME/.0L/fullnode.node.yaml 2>&1 | multilog s104857600 n10 $HOME/.0L/logs/node' C-m
                                    sleep 180

                                    cat $HOME/bin/keygen.txt &&
                                    echo -e "Open a new terminal and change user [ \e[1m\e[32msudo su node\e[0m ], attach TMUX session [ \e[1m\e[32mtmux attach -t $session\e[0m ], copy and paste your mnemonic."
                                    echo ""
                                    echo ""
                                    sleep 30

                                    session="validator_log"
                                    tmux new-session -d -s $session
                                    window=0
                                    tmux rename-window -t $session:$window 'validator_log'

                                    J=1
                                    K=10
                                    while [ $J -lt $K ]
                                    do                                    
                                        if [ -s $HOME/.0L/logs/node/current ]
                                        then
                                            tmux send-keys -t $session:$window 'tail -f $HOME/.0L/logs/node/current' C-m
                                            echo -e "Validator started! It is run as \e[1m\e[33m\"fullnode mode\" \e[0mnow."
                                            echo "You can restart node as \"validator\" mode after fully synced and onboarded by other an active validator."
                                            echo ""
                                            sleep 2

                                            echo ""
                                            echo -e "\e[1m\e[32m7. Checking sync status.. \e[0m"
                                            echo "===================="
                                            echo ""
                                            echo "Waiting validator is stabled and start syncing.. Be patient, please."
                                            echo ""
                                            sleep 300

                                            syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                            echo $syn &&
                                            export syn1=$(echo $syn | grep -o '[0-9]*') &&
                                            echo ""
                                            echo "Checking highest versions until figures increase.." &&
                                            echo ""
                                            S=1
                                            SS=15
                                            while [ $S -lt $SS ]
                                            do
                                                sleep 20
                                                export syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                                echo $syn &&
                                                export syn2=$(echo $syn | grep -o '[0-9]*') &&
                                                if [ $syn2 == $syn1 ]
                                                then
                                                    export S=`expr $S + 1`
                                                else
                                                    SS=1
                                                fi
                                            done

                                            export delt=$((syn2 - syn1)) &&
                                            export TP=$(echo "scale=3; $delt / ( 20 * $S )" | bc) &&
                                            if [ $delt -gt 0 ]
                                            then
                                                echo ""
                                                echo -e "\e[1m\e[32mNetwork alive! \e[0m"
                                                echo ""
                                                echo ""
                                            else
                                                echo ""
                                                echo ">>> Network highest version is not changed during 5 minutes.. Checking skipped. <<<"
                                                echo ""
                                            fi

                                            sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                            echo $sync &&
                                            export sync1=$(echo $sync | grep -o '[0-9]*') &&
                                            echo ""
                                            echo "Checking synced versions until figures increase.." &&
                                            echo ""

                                            S=1
                                            SS=15
                                            while [ $S -lt $SS ]
                                            do
                                                sleep 20
                                                export sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                                echo $sync &&
                                                export sync2=$(echo $sync | grep -o '[0-9]*') &&
                                                if [ $sync2 == $sync1 ]
                                                then
                                                    export S=`expr $S + 1`
                                                else
                                                    SS=1
                                                fi
                                            done

                                            export delta=$((sync2 - sync1)) &&
                                            if [ $delta -gt 0 ]
                                            then
                                                echo ""
                                                echo -e "\e[1m\e[32mYour validator is syncing now! \e[0m"
                                                echo ""
                                            else
                                                echo ""
                                                echo ">>> Validator synced version is not changed at all during 5 minutes.. It's critical! <<<"
                                                exit
                                            fi

                                            export TPS=$(echo "scale=3; $delta / ( 20 * $S )" | bc) &&
                                            export SPEED=$(echo "scale=3; $TPS - $TP" | bc) &> /dev/null &&
                                            echo ""
                                            echo "===================="
                                            echo -e "Network TPS : \e[1m\e[32m$TP \e[0m[tx/s]"
                                            echo -e "Local   TPS : \e[1m\e[32m$TPS \e[0m[tx/s]"
                                            echo "===================="
                                            echo ""
                                            if [[ `echo "$SPEED > 0" | bc` -eq 0 ]]
                                            then
                                                echo ">>> Validator is syncing but too slow to catch up, so you need to restore and restarted manually later! <<<"
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

                                            tmux send-keys -t $session:$window 'export NODE_ENV=prod && $HOME/bin/tower -o start >> $HOME/.0L/logs/tower.log 2>&1' C-m
                                            sleep 5

                                            echo ""
                                            echo ""
                                            sleep 30

                                            session="tower_log"
                                            tmux new-session -d -s $session
                                            window=0
                                            tmux rename-window -t $session:$window 'tower_log'
                                            sleep 1

                                            tmux send-keys -t $session:$window 'tail -f $HOME/.0L/logs/tower.log' C-m
                                            
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

                                            tmux send-keys -t $session:$window 'cd $HOME/libra && make web-files && $HOME/bin/ol serve -c' C-m

                                            echo ""
                                            echo "Monitor started!"
                                            echo ""
                                            echo ""
                                            echo -e "From now, you can monitor your node in browser by typing [ \e[1m\e[32mhttp://your_IP:3030 \e[0m]"
                                            echo ""
                                            AUTH=$(sed -n '7p' $HOME/bin/keygen.txt)
                                            echo ""
                                            echo "To run tower and mine successfully, you should be onboarded by someone who can onboard you with a transaction below."
                                            echo -e "[ \e[1m\e[32mtxs create-validator --account-file /path/to/\"your_account.json\" \e[0m] if you want to run \e[1m\e[33m\"validator\" \e[0m"
                                            echo -e "[ \e[1m\e[32mtxs create-account --authkey $AUTH --coins 1 \e[0m] if you want to run \e[1m\e[33m\"fullnode\" \e[0mmode only"
                                            echo ""
                                            sleep 2
                                            tmux ls > $HOME/bin/tmux_status.txt &&
                                            sleep 2
                                            echo -e "\e[1m\e[32m[ TMUX sessions ] \e[0m"
                                            echo "===================="
                                            cat -n $HOME/bin/tmux_status.txt
                                            echo "===================="
                                            echo ""
                                            sleep 1

                                            echo ""
                                            echo "Script for TMUX completed! Installation is successful!"
                                            echo ""
                                            A=15
                                            E=15
                                            G=15
                                            J=15
                                        fi
                                    done
                                fi
                            fi
                        done
                    fi
                done
            fi
        fi
    fi
done
