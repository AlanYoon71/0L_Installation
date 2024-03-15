#!/bin/bash

clear
echo ""
echo "";
echo "░▒▓████████▓▒░▒▓█▓▒░             ░▒▓███████▓▒░░▒▓████████▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░    ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓███████▓▒░  ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓████████▓▒░▒▓████████▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░  ░▒▓█▓▒░    ░▒▓█████████████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "";
echo ""
echo ""
echo ""
echo -e "\e[1m\e[32m1. Prepare environment for libra node setup.\e[0m"
cd ~
apt update
apt install sudo
sudo apt install nano
sudo apt update
sudo apt install -y git wget nano bc tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev
sudo apt install curl
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
source ~/.bashrc

echo ""
echo -e "\e[1m\e[32m2. Build framework for libra node.\e[0m"
if [ -f "framework_check.txt" ]; then
    :
else
    git clone https://github.com/0LNetworkCommunity/libra-framework
    echo "This script has downloaded framework." > framework_check.txt
fi
cd ~/libra-framework
bash ./util/dev_setup.sh -t
source ~/.bashrc
cd ~/libra-framework

echo ""
echo -e "\e[1m\e[32m3. Build binaries for libra node.\e[0m"
git fetch
git pull
cargo build --release -p libra
sudo cp -f ~/libra-framework/target/release/libra* ~/.cargo/bin/
libra --version

echo ""
echo -e "\e[1m\e[32m4. Initialize validator's configs.\e[0m"
echo ""
echo "Do you want to keygen for your new wallet? (y/n)"
read -p "y/n : " user_input
if [[ $user_input == "y" ]]; then
    echo ""
    libra wallet keygen
elif [[ $user_input == "n" ]]; then
    :
fi
echo ""
sleep 3
libra config validator-init
libra config fix --force-url https://rpc.openlibra.space:8080
libra config fullnode-init
libra config fix --force-url https://rpc.openlibra.space:8080
#grep full_node_network_public_key ~/.libra/public-keys.yaml # copy key
#nano ~/.libra/operator.yaml #paste key
sudo ufw allow 22; sudo ufw allow 3000; sudo ufw allow 6180; sudo ufw allow 6181; sudo ufw allow 6182; sudo ufw allow 8080; sudo ufw allow 9101;
sudo ufw enable;

echo ""
echo -e "\e[1m\e[32m5. Start libra node in tmux session.\e[0m"
mkdir ~/.libra/logs &> /dev/null;
session="node" &> /dev/null;
tmux new-session -d -s $session &> /dev/null;
window=0
tmux rename-window -t $session:$window 'node' &> /dev/null;
tmux send-keys -t node:0 "RUST_LOG=info libra node >> ~/.libra/logs/validator.log" C-m
echo "Checking fullnode's sync status..."
sleep 10
SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
sleep 30
SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
if [[ $SYNC1 -eq $SYNC2 ]]
then
    echo ""
    echo "Node is not syncing now. Check node's status, please."
    echo "Node is not syncing now. Check node's status, please."
else
    echo ""
    echo -e "\e[1m\e[32mNode is syncing now! Installed successfully.\e[0m"
fi
address=`grep -oP '(?<=account: )\w+' ~/.libra/libra.yaml`
echo ""
echo "You need additional 4 actions as below to join validator set."
echo "============================================================="
echo "1. Onboard with this command by another node. (for fullnode and validator both)"
echo "   Command : libra txs transfer --to-account $address --amount 5"
echo ""
echo "2. Register validator with this command by yourself. (for validator)"
echo "   Command : libra txs validator register"
echo ""
echo "3. Request the vouches with this command from other validators in the set. (for validator)"
echo "   Command : libra txs validator vouch --vouch-for $address"
echo ""
echo "4. Bid to be in the validator set. (for validator)"
echo "   Command : libra txs validator pof --bid-pct 0.1 --expiry 1000"
echo "============================================================="
echo ""
sleep 5
tmux ls
echo ""
echo "Check your tmux sessions."
echo ""
curl -s localhost:8080/v1/ | jq
sleep 3
echo ""
echo "Done."
echo ""
