
session="fullnode"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'fullnode'
tmux send-keys -t $session:$window 'cd && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && . ~/.bashrc && cargo install toml-cli && git clone https://github.com/OLSF/libra.git && cd /home/node/libra && make bins install' C-m

sleep 1200

tmux send-keys -t $session:$window '\n
cd /home/node/bin && ./ol serve --update && ./onboard keygen > keygen.txt && cat keygen.txt && AUTH=$(sed -n '7p' keygen.txt) && MNEM=$(sed -n '11p' keygen.txt) && cd $HOME/.0L && mkdir logs && /home/node/bin/onboard user' C-m

sleep 300
tmux kill-session -t $session

sleep 5

session="fullnode"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'fullnode'
tmux send-keys -t $session:$window '/home/node/bin/ol restore && ulimit -n 100000 && cd /home/node/.0L && diem-node --config ~/.0L/fullnode.node.yaml  >> ~/.0L/logs/node.log 2>&1 && tail -f ~/.0L/logs/node.log' C-m


echo ""
echo "Fullnode started!"
echo ""

sleep 300

session="tower"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'tower'
tmux send-keys -t $session:$window 'export NODE_ENV=prod && /home/node/bin/tower start' C-m
echo ""
echo "Tower started!"
echo ""

sleep 60

session="monitor"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'monitor'
tmux send-keys -t $session:$window 'cd /home/node/libra && make web-files && /home/node/bin/ol serve -c' C-m
echo ""
echo "Monitor started!"
echo ""
echo "Done!!"
echo ""
echo ""
curl icanhazip.com > ip.txt && IP=$(cat ./ip.txt)
echo "From now, you can monitor your node in browser by typing [ http://$IP:3030 ]"
