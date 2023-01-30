#!/bin/bash
session="onboarding"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'fullnode'

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
echo -e "\e[1m\e[32m>>> From now you can open your tmux session in another terminal[ tmux attach -t $session ] <<< \e[0m"
echo -e "\e[1m\e[32m>>> In $session session screen, copy your mnemonic displayed in monitor, paste it and write your answer(y/n or statement). <<< \e[0m"
echo "===================="
echo ""
echo "And then just wait until your first mining complete(20 ~ 30min) and this $session session close automatically."
echo ""
echo ""

sleep 30

echo ""
echo "If you complete upper actions and prove you are human, genesis proof and config files will be created."
echo "When all required files are created, your fullnode and tower will be started automatically."
echo ""
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
                echo "All required files are already created successfully!"
                echo ""
                sleep 3
                echo -e "\e[1m\e[32m4. Starting fullnode and tower.. \e[0m"
                echo "===================="
                tmux kill-session -t $session
                sleep 2
                session="fullnode"
                tmux new-session -d -s $session
                window=0
                tmux rename-window -t $session:$window 'fullnode'

                sleep 1
                
                tmux send-keys -t $session:$window 'ulimit -n 100000 && /home/node/bin/ol --config /home/node/.0L/0L.toml query --epoch > waypoint.txt && STR=$(cat /home/node/bin/waypoint.txt) && echo "${STR:(-73)}" > /home/node/bin/waypoint.txt && WAY=$(cat /home/node/bin/waypoint.txt) && sleep 2 && /home/node/bin/ol init --key-store --waypoint $WAY' C-m
                
                sleep 10
                
                tmux send-keys -t $session:$window '/home/node/bin/ol restore && cd /home/node/.0L && sleep 3 & diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1' C-m

                echo ""
                echo -e "\e[1m\e[32m>>> Open your tmux session in another terminal[ tmux attach -t $session ], copy and paste your mnemonic into $session session screen. <<< \e[0m"
                echo "===================="
                echo ""

                sleep 300

                session="fullnode_log"
                tmux new-session -d -s $session
                window=0
                tmux rename-window -t $session:$window 'fullnode_log'
                
                sleep 1
                
                tmux send-keys -t $session:$window 'tail -f ~/.0L/logs/node.log' C-m

                echo ""
                echo "Fullnode started!"
                echo ""

                sleep 300

                session="tower"
                tmux new-session -d -s $session
                window=0
                tmux rename-window -t $session:$window 'tower'
                
                sleep 1
                
                tmux send-keys -t $session:$window 'MNEM=$(sed -n '11p' /home/node/bin/keygen.txt)' C-m
                
                sleep 1

                tmux send-keys -t $session:$window 'cat /home/node/bin/keygen.txt' C-m
                
                sleep 1
                
                tmux send-keys -t $session:$window 'export NODE_ENV=prod && /home/node/bin/tower start && echo -e $MNEM"\n"' C-m

                echo ""
                echo -e "\e[1m\e[32m>>> Open your tmux session in another terminal[ tmux attach -t $session ], copy and paste your mnemonic into $session session screen. <<< \e[0m"
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
                IP=$(sed -n '1p' /home/node/bin/ip.txt)
                echo "From now, you can monitor your node in browser by typing [ http://$IP:3030 ]"
                echo ""
                AUTH=$(sed -n '7p' /home/node/bin/keygen.txt) 
                echo -e "\e[1m\e[32m>>> Don't forget this! <<<
                For operating tower and mining successfully, you should request onboarding to anyone who can onboard you with a transaction below.
                [ txs create-account --authkey $AUTH --coins 1 ] \e[0m"
                echo "===================="
                echo ""
                echo -e "\e[1m\e[32m>>>TMUX sessions created by this script <<< \e[0m"
                echo "===================="
                cat -n /home/node/bin/tmux_status.txt
                echo "===================="
                echo ""
                echo ""
                echo -e "\e[1m\e[32mDone!! \e[0m"
                echo ""
                A=15
            fi
        else
        sleep 60
        fi
    else
    sleep 60
    fi
done

