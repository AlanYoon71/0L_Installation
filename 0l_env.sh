#!/bin/bash
clear
echo ""
echo "================================"
echo ""
echo "Script from  //-\ ][_ //-\ ][\[ ";
echo ""
echo "================================"
echo ""
cd ~
echo -e "\e[1m\e[32m1. Installing dependencies.. \e[0m"
echo "===================="
sleep 2
apt install -y git vim zip unzip bc jq build-essential cmake clang llvm libgmp-dev secure-delete pkg-config libssl-dev lld tmux
echo ""
echo -e "\e[1m\e[32m2. Installing required linux packages.. \e[0m"
echo "===================="
sleep 2
curl -sL https://raw.githubusercontent.com/OLSF/libra/main/ol/util/setup.sh | bash
echo ""
echo ""
echo ""
echo ""
echo "All required packages installed."
echo ""
echo ""
echo -e "\e[1m\e[32m3. Compiling binary files.. \e[0m"
echo "===================="
echo ""
echo "This script includes tower and genesis mining, so it takes 1 hour more entirely until all processes completed, so be patient, please."
echo ""
sudo useradd node -m -s /bin/bash
cp ./0l_tmux.sh /home/node
chmod +x /home/node/0l_tmux.sh
chmod go+rw /home/node/0l_tmux.sh
sudo -u node /home/node/0l_tmux.sh
