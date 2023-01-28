#!/bin/bash
echo ""
echo "================================"
echo ""
echo "Script from  //-\ ][_ //-\ ][\][ ";
echo ""
echo "================================"
echo ""
cd ~
echo "Installing dependencies.."
echo "===================="
sleep 2
sudo apt install -y git vim zip unzip jq build-essential cmake clang llvm libgmp-dev secure-delete pkg-config libssl-dev lld tmux
echo ""
echo "Installing required packages.."
echo "===================="
sleep 2
curl -sL https://raw.githubusercontent.com/OLSF/libra/main/ol/util/setup.sh | bash
echo ""
echo "Entering tmux session and installing 0l fullnode.."
echo "===================="
sleep 2
SESSIONNAME="install"
tmux has-session -t $SESSIONNAME 2> /dev/null
if [ $? != 0 ] 
  then
    tmux new-session -s $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "cd && git clone https://github.com/OLSF/libra.git && cd $HOME/libra" C-m
    tmux send-keys -t $SESSIONNAME ". ol/util/setup.sh && make bins install && exit" C-m
fi
cd $HOME/libra
SESSIONNAME="fullnode"
tmux has-session -t $SESSIONNAME 2> /dev/null
if [ $? != 0 ] 
  then
    tmux new-session -s $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "ol serve --update && exit" C-m
fi
echo ""
echo "Generating your keys.."
echo "===================="
sleep 2
onboard keygen > keygen.txt && cat keygen.txt
AUTH=$(sed -n '7p' keygen.txt)
MNEM=$(sed -n '11p' keygen.txt)
echo ""
echo "Preparing to onboard.."
echo "===================="
sleep 2
SESSIONNAME="fullnode"
tmux has-session -t $SESSIONNAME 2> /dev/null
if [ $? != 0 ] 
  then
    tmux new-session -s $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "cd $HOME/.0L && mkdir logs && curl icanhazip.com > ip.txt && IP=$(./ip.txt)" C-m
    tmux send-keys -t $SESSIONNAME "ol init -u http://$IP:8080" C-m
    tmux send-keys -t $SESSIONNAME "onboard user" C-m
fi
echo ""
echo "Fullnode is already installed and syncing."
echo "You can check fullnode logs by typing [ tmux attach -t fullnode ]"
echo "If you want to change fullnode to background process, press [ Ctrl+b, d ]"
echo "===================="
sleep 3
echo ""
echo "Ask for onboarding to anyone who runs fullnode or carpe by sending message below."
echo "===================="
echo "txs create-account --authkey $AUTH --coins 1"
echo "===================="
sleep 5
echo ""
echo "Running tower and monitor.."
echo "===================="
sleep 2
SESSIONNAME="tower"
tmux has-session -t $SESSIONNAME 2> /dev/null
if [ $? != 0 ] 
  then
    tmux new-session -s $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "export NODE_ENV=prod && tower start >> ~/.0L/logs/tower.log 2>&1 && echo $MNEM" C-m
fi
echo ""
echo "From now, you can check your tower logs by typing [ tail -f $HOME/.0L/logs/tower.log ]"
SESSIONNAME="monitor"
tmux has-session -t $SESSIONNAME 2> /dev/null
if [ $? != 0 ] 
  then
    tmux new-session -s $SESSIONNAME
    tmux send-keys -t $SESSIONNAME "cd $HOME/libra && make web-files && ol serve -c" C-m
fi
sleep 2
echo ""
echo "And you can monitor your fullnode in browser by typing [ http://$IP:3030 ]"
echo ""
echo ""
sleep 2
echo "0L Fullnode Installation is completed!"