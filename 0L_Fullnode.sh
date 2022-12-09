#!/bin/bash
echo ""
echo "================================"
echo ""
echo "Script from  //-\ ][_ //-\ ][\][ ";
echo ""
echo "================================"
echo ""
cd ~
echo "Adding and entering user node"
sleep 1
sudo useradd node -m -s /bin/bash && sudo su node
echo ""
echo "Using tmux entering session fullnode"
sleep 1
tmux 
echo "Installing fullnode for 0L now..."
git clone https://github.com/OLSF/libra.git
cd libra
. ol/util/setup.sh
sleep 1
make bins install
SESSIONNAME="script"
tmux has-session -t $SESSIONNAME 2> /dev/null

if [ $? != 0 ] 
  then
    tmux new-session -s $SESSIONNAME -n script -d "bin/zsh"
    tmux send-keys -t $SESSIONNAME "cd /home/wanderlust/Ibiza" C-m
    tmux send-keys -t $SESSIONNAME "hugo server --bind 0.0.0.0 --port 8000 --disableFastRender" C-m
fi