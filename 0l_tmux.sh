#!/bin/bash
session="onboarding"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'onboarding'

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
echo -e "Open your tmux session \e[1m\e[32m[ tmux attach -t $session ] \e[0min a new terminal by user node(not root), copy and paste your mnemonic, answer questions."
echo ""
echo "And then just wait until your first mining is completed. This mining takes 30 ~ 50min, up to server's CPU performance."
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
                echo "Genesis proof created successfully!"
                echo ""
                sleep 3
                
                tmux send-keys -t $session:$window 'ulimit -n 100000 && /home/node/bin/ol restore && /home/node/.0L && /home/node/bin/diem-node --config ~/.0L/fullnode.node.yaml' C-m  
                sleep 180

                tmux send-keys -t $session:$window '/home/node/bin/ol --config /home/node/.0L/0L.toml query --epoch > /home/node/bin/waypoint.txt && STR=$(cat /home/node/bin/waypoint.txt) && echo "${STR:(-73)}" > /home/node/bin/waypoint.txt && WAY=$(cat /home/node/bin/waypoint.txt) && echo ${#WAY} > /home/node/bin/waylength.txt' C-m
                sleep 10

                echo ""
                echo -e "\e[1m\e[32m5. Updating fullnode configurations.. \e[0m"
                echo "===================="
                echo ""

                #tmux kill-session -t $session
                #sleep 3
                
                # session="restoring"
                # tmux new-session -d -s $session
                # window=0
                # tmux rename-window -t $session:$window 'restoring'
                # sleep 1

                # tmux send-keys -t $session:$window 'killall diem-node > /dev/null ; sleep 3 && ulimit -n 100000 && /home/node/bin/ol restore && diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1' C-m
                # sleep 60

                # session="waypoint"
                # tmux new-session -d -s $session
                # window=0
                # tmux rename-window -t $session:$window 'waypoint'
                # sleep 1

                # tmux send-keys -t $session:$window 'cd /home/node/.0L && /home/node/bin/ol --config /home/node/.0L/0L.toml query --epoch > /home/node/bin/waypoint.txt && STR=$(cat /home/node/bin/waypoint.txt) && echo "${STR:(-73)}" > /home/node/bin/waypoint.txt && WAY=$(cat /home/node/bin/waypoint.txt) && echo ${#WAY} > /home/node/bin/waylength.txt && cat /home/node/bin/keygen.txt && /home/node/bin/ol init --key-store --waypoint $WAY' C-m
                # sleep 60

                # echo ""
                # echo -e "Open your tmux session \e[1m\e[32m[ tmux attach -t $session ] \e[0min a new terminal by user node(not root), copy and paste your mnemonic."
                # echo ""

                E=1
                F=10
                W=73
                #waylength=$(cat /home/node/bin/waylength.txt)
                while [ $E -lt $F ]
                do
                    sleep 60
                    if [ "$waylength" == "$W" ]
                    then
                        echo ""
                        echo "Lastest waypoint fetched successfully!"
                        echo ""

                        tmux kill-session -t $session
                        sleep 3

                        G=1
                        H=10
                        #waylength=$(cat /home/node/bin/waylength.txt)
                        while [ $G -lt $H ]
                        do                        
                            sleep 60
                            #WAY=$(cat /home/node/bin/waypoint.txt)
                            if [ -f /home/node/.0L/key_store.json ]
                            #if [[ -n `grep $WAY /home/node//bin/waypoint.txt` ]]
                            then
                                #echo ""
                                #echo "Configuration of key_store.json updated!"
                                #echo ""
                                # session="update"
                                # tmux new-session -d -s $session
                                # window=0
                                # tmux rename-window -t $session:$window 'update'
                                # sleep 1

                                #tmux send-keys -t $session:$window 'cd /home/node/.0L && /home/node/bin/ol --config /home/node/.0L/0L.toml query --epoch > /home/node/bin/waypoint.txt && STR=$(cat /home/node/bin/waypoint.txt) && echo "${STR:(-73)}" > /home/node/bin/waypoint.txt && WAY=$(cat /home/node/bin/waypoint.txt)' C-m
                                #sleep 10
                                tmux send-keys -t $session:$window 'sed -i'' -r -e "/tx_configs.baseline_cost/i\base_waypoint = \"$WAY\"" /home/node/.0L/0L.toml' C-m
                                sleep 5
                                tmux send-keys -t $session:$window 'sed -i "s/tx = 10000/tx = 20000/g" /home/node/.0L/0L.toml' C-m
                                sleep 3
                                tmux send-keys -t $session:$window 'sed -i "s/tx = 1000/tx = 20000/g" /home/node/.0L/0L.toml' C-m
                                sleep 3

                                echo ""
                                echo "Fullnode configuration updated!"
                                echo ""
                                sleep 3

                                echo ""
                                echo -e "\e[1m\e[32m6. Starting fullnode.. \e[0m"
                                echo "===================="
                                echo ""

                                session="fullnode"
                                tmux new-session -d -s $session
                                window=0
                                tmux rename-window -t $session:$window 'fullnode'
                                sleep 1
                                
                                tmux send-keys -t $session:$window 'ulimit -n 100000 && killall diem-node > /dev/null ; sleep 3 && /home/node/bin/ol restore && sleep 3 && cd /home/node/.0L && /home/node/bin/diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1' C-m
                                sleep 180
                                
                                session="node_log"
                                tmux new-session -d -s $session
                                window=0
                                tmux rename-window -t $session:$window 'node_log'
                                sleep 1
                                
                                tmux send-keys -t $session:$window 'tail -f ~/.0L/logs/node.log' C-m
                                
                                if [ -s /home/node/logs/node.log ]
                                then
                                    echo ""
                                    echo "Fullnode started!"
                                    echo ""
                                    sleep 180

                                    echo ""
                                    echo -e "\e[1m\e[32m7. Checking sync status.. \e[0m"
                                    echo "===================="
                                    echo ""
                                    syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                    sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                    echo $syn &&
                                    echo $sync &&
                                    syn1=$(echo $syn | grep -o '[0-9]*') &&
                                    sync1=$(echo $sync | grep -o '[0-9]*') &&
                                    sleep 30
                                    echo ""
                                    echo "Checking if version is increasing in 10 seconds interval" &&
                                    echo ""
                                    syn=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"highest\") &&
                                    sync=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\") &&
                                    echo $syn &&
                                    echo $sync &&
                                    syn2=$(echo $syn | grep -o '[0-9]*') &&
                                    sync2=$(echo $sync | grep -o '[0-9]*') &&
                                    delt=$((syn2 - syn1)) &&
                                    #TP=$((delt / 30)) &&
                                    TP=$(echo "scale=2; $delt / 30" | bc) &&
                                    delta=$((sync2 - sync1)) &&
                                    if [ $delta -gt 0 ]
                                    then
                                        echo ""
                                        echo "Fullnode syncing works!!"
                                        echo ""
                                    else
                                        echo ""
                                        echo ">>> Fullnode not works normally. Syncing stopped... <<<"
                                        exit
                                    fi
                                    
                                    TPS=$(echo "scale=2; $delta / 30" | bc) &&
                                    echo ""
                                    echo "===================="
                                    echo -e "Network TPS : \e[1m\e[32m$TP \e[0m[tx/s]"
                                    echo -e "Local   TPS : \e[1m\e[32m$TPS \e[0m[tx/s]"
                                    echo "===================="
                                    echo ""
                                    LAG=$((syn2 - sync2)) &&
                                    SPEED=$(echo "scale=2; $TPS - $TP" | bc) &&
                                    CATCH=$(echo "scale=2; $LAG / $SPEEED / 3600" | bc) &&
                                    echo "===================="
                                    echo -e "Syncing Lag(current) : \e[1m\e[35m$LAG \e[0m"
                                    echo -e "Catch Up Time  (est) : \e[1m\e[35m$CATCH \e[0m[Hr]"
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

                                    echo ""
                                    echo -e "Open your tmux session \e[1m\e[32m[ tmux attach -t $session ] \e[0min a new terminal by user node(not root), copy and paste your mnemonic."
                                    sleep 2

                                    if [ -s /home/node/.0L/logs/tower.log ]
                                    then
                                        echo ""
                                        echo "Tower started!"
                                        echo "Tower can start to submit proofs on chain after fullnode finish catch up for fully syncing."
                                        echo ""
                                    else
                                        echo ""
                                        echo -e "\e[1m\e[32m>>> Tower not works normally. check out $session session... <<< \e[0m"
                                        echo ""
                                        exit
                                    fi
                                    
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
                                    echo -e "From now, you can monitor your node in browser by typing \e[1m\e[32m[ http://your_IP:3030 ] \e[0m"
                                    echo ""
                                    AUTH=$(sed -n '7p' /home/node/bin/keygen.txt)
                                    echo "To run tower and mine successfully, you should be onboarded by anyone who can onboard you with a transaction below."
                                    echo -e "\e[1m\e[32m[ txs create-account --authkey $AUTH --coins 1 ] \e[0m"
                                    sleep 2

                                    echo ""
                                    echo -e "\e[1m\e[32m[ TMUX sessions ] \e[0m"
                                    echo "===================="
                                    cat -n /home/node/bin/tmux_status.txt
                                    echo "===================="
                                    echo ""
                                    cat /home/node/bin/keygen.txt
                                    sleep 1
                                    rm /home/node/bin/keygen.txt && rm /home/node/bin/waylength.txt && rm /home/node/bin/waypoint.txt
                                    echo ""
                                    echo ""
                                    echo -e "\e[1m\e[32mDone!! \e[0m"
                                    echo ""
                                    A=15
                                    E=15
                                    G=15
                                else
                                    echo ""
                                    echo ">>> Fullnode failed to start... <<<"
                                    exit
                                fi
                            fi
                        done
                    fi
                done
            fi
        fi
    fi
done
