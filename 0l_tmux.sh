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
        echo "Binary files for 0l are already compiled successfully!"
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
echo "And then just wait until your first mining completed.(20 ~ 40min)"
echo ""

A=1
B=10
while [ $A -lt $B ]
do
    if [ -f /home/node/.0L/0L.toml ]
    then
        if [ -f /home/node/.0L/account.json ]
        then
            if [ -f /home/node/.0L/vdf_proofs/proof_0.json ]
            then
                sleep 60
                echo ""
                echo "Genesis proof created successfully!"
                echo ""
                sleep 3
                
                echo ""
                echo -e "\e[1m\e[32m5. Updating fullnode configurations.. \e[0m"
                echo "===================="
                echo ""

                tmux kill-session -t $session
                sleep 3
                
                session="fullnode"
                tmux new-session -d -s $session
                window=0
                tmux rename-window -t $session:$window 'fullnode'
                sleep 1

                tmux send-keys -t $session:$window 'ulimit -n 100000 && /home/node/bin/ol restore && diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1'
                sleep 60

                session="waypoint"
                tmux new-session -d -s $session
                window=0
                tmux rename-window -t $session:$window 'waypoint'
                sleep 1

                tmux send-keys -t $session:$window '/home/node/bin/ol --config /home/node/.0L/0L.toml query --epoch > /home/node/bin/waypoint.txt && STR=$(cat /home/node/bin/waypoint.txt) && echo "${STR:(-73)}" > /home/node/bin/waypoint.txt && WAY=$(cat /home/node/bin/waypoint.txt) && waylength=$(echo ${#WAY}) && cat /home/node/bin/keygen.txt && /home/node/bin/ol init --key-store --waypoint $WAY' C-m
                sleep 60

                if [ 73 -eq "$waylength" ]
                then
                    echo ""
                    echo "Lastest waypoint fetched successfully!"
                    echo ""
                    echo ""
                    echo -e "Open your tmux session \e[1m\e[32m[ tmux attach -t $session ] \e[0min a new terminal by user node(not root), copy and paste your mnemonic."
                    echo ""

                    session="update"
                    tmux new-session -d -s $session
                    window=0
                    tmux rename-window -t $session:$window 'update'
                    sleep 1
                                        
                    tmux send-keys -t $session:$window 'WAY=$(cat /home/node/bin/waypoint.txt) && sed -i'' -r -e "/tx_configs.baseline_cost/i\base_waypoint = "$WAY"" /home/node/.0L/0L.toml' C-m
                    sleep 5
                    tmux send-keys -t $session:$window 'sed -i "s/tx = 10000/tx = 20000/g" /home/node/.0L/0L.toml' C-m
                    sleep 3
                    tmux send-keys -t $session:$window 'sed -i "s/tx = 1000/tx = 20000/g" /home/node/.0L/0L.toml' C-m
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
                    
                    tmux send-keys -t $session:$window 'ulimit -n 100000 && killall diem-node && sleep 3 && /home/node/bin/ol restore && sleep 3 && cd /home/node/.0L && diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1' C-m
                    sleep 180
                    
                    session="node_log"
                    tmux new-session -d -s $session
                    window=0
                    tmux rename-window -t $session:$window 'node_log'
                    sleep 1
                    
                    tmux send-keys -t $session:$window 'tail -f ~/.0L/logs/node.log' C-m
                    
                    echo ""
                    echo "Fullnode started!"
                    echo ""
                    sleep 180

                    echo ""
                    echo -e "\e[1m\e[32m7. Starting tower.. \e[0m"
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

                    tmux send-keys -t $session:$window 'export NODE_ENV=prod && /home/node/bin/tower start' C-m
                    sleep 5

                    echo ""
                    echo -e "Open your tmux session \e[1m\e[32m[ tmux attach -t $session ] \e[0min a new terminal by user node(not root), copy and paste your mnemonic."
                    echo "===================="
                    
                    echo ""
                    echo "Tower started!"
                    echo ""
                    sleep 2
                    
                    session="monitor"
                    tmux new-session -d -s $session
                    window=0
                    tmux rename-window -t $session:$window 'monitor'
                    sleep 1
                    
                    tmux send-keys -t $session:$window 'tmux ls > /home/node/bin/tmux_status.txt' C-m
                    sleep 1
                    
                    tmux send-keys -t $session:$window 'cd /home/node/libra && make web-files && /home/node/bin/ol serve -c' C-m
                    
                    echo ""
                    echo "Monitor started! All of binary files are started now."
                    echo ""
                    echo ""
                    echo "From now, you can monitor your node in browser by typing \e[1m\e[32m[ http://your_IP:3030 ] \e[0m"
                    echo ""
                    AUTH=$(sed -n '7p' /home/node/bin/keygen.txt)
                    echo "To run tower and mine successfully, you should be onboarded by anyone who can onboard you with a transaction below."
                    echo -e "\e[1m\e[32m[ txs create-account --authkey $AUTH --coins 1 ] \e[0m"
                    echo "===================="
                    echo ""
                    echo -e "\e[1m\e[32m[ TMUX sessions ] \e[0m"
                    echo "===================="
                    cat -n /home/node/bin/tmux_status.txt
                    echo "===================="
                    echo ""
                    echo ""
                    echo -e "\e[1m\e[32mDone!! \e[0m"
                    echo ""
                    A=15
                else
                    echo ""
                    echo -e "\e[1m\e[35m>>> UPDATE FAILED!! It's so critical... <<< \e[0m"
                    echo ""
                fi            
            fi
        else
            sleep 60
        fi
    else
        sleep 60
    fi
done
