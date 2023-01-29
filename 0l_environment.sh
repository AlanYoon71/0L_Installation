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
apt install -y git vim zip unzip jq build-essential cmake clang llvm libgmp-dev secure-delete pkg-config libssl-dev lld tmux
echo ""
echo "Installing required packages.."
echo "===================="
sleep 2
curl -sL https://raw.githubusercontent.com/OLSF/libra/main/ol/util/setup.sh | bash
echo ""
echo "0l environment installation finished"
echo ""
echo "Changing user from root to node and installing.. It takes about 30min more, so be patient until finishing installation."
echo "===================="
sudo useradd node -m -s /bin/bash
cp ./0l_tmux.sh /home/node
chmod +x /home/node/0l_tmux.sh
chmod go+rw /home/node/0l_tmux.sh
sudo -u node /home/node/0l_tmux.sh
