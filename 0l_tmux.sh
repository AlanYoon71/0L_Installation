
session="install"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'preparing'
tmux send-keys -t $session:$window 'cd && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && . ~/.bashrc && cargo install toml-cli && git clone https://github.com/OLSF/libra.git && cd /home/node/libra && make bins install && cd /home/node/bin && ./ol serve --update && onboard keygen > keygen.txt && cat keygen.txt && AUTH=$(sed -n '7p' keygen.txt) && MNEM=$(sed -n '11p' keygen.txt) && cd $HOME/.0L && mkdir logs && curl icanhazip.com > ip.txt && IP=$(./ip.txt) && cd /home/node/bin && ./ol init -u http://$IP:8080 && ./onboard user' C-m

sleep 2400
session="tower"
tmux new-session -d -s $session
window=0
tmux new-window -t $session:$window -n 'tower'
tmux send-keys -t $session:$window 'export NODE_ENV=prod && tower start' C-m


sleep 10
session="monitor"
window=0
tmux new-window -t $session:$window -n 'monitor'
tmux send-keys -t $session:$window 'cd /home/node/libra && make web-files && cd /home/node/bin && ./ol serve -c' C-m

echo "Done!!"
echo ""
echo ""
echo "Check your tower logs by typing [ tail -f $HOME/.0L/logs/tower.log ] and monitor your node in browser by typing [ http://$IP:3030 ]"
