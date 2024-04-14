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

new=0
echo -e "\e[1m\e[32m1. Installing packages for libra node setup.\e[0m"

sleep 2
echo ""
cd ~
apt update
apt install sudo
sudo apt update
sudo apt install nano
while true; do
    echo ""
    echo "Input your github token."
    read -p "token : " token
    echo ""
    echo "Your github token is $token."
    echo ""
    echo "Did you enter it correctly?(y/n)"
    read -p "y/n : " user_input
    if [[ $user_input == "y" ]]; then
        echo ""
        break
    fi
done
echo $token $HOME/github_token.txt
cd ~
sudo apt update && sudo apt install -y git wget nano bc tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev
sudo apt install curl && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && source ~/.bashrc
export PATH="$HOME/.cargo/bin:$PATH"
rustup update && rustup default stable
cargo install cargo-nextest && cargo nextest --version
if [ -d "$HOME/libra-framework" ]; then
    cd ~/libra-framework
else
    git clone https://github.com/0LNetworkCommunity/libra-framework
    cd ~/libra-framework    
fi
git fetch --all
git checkout release-7.0.0
git log -n 1 --pretty=format:"%H"
cd ~/libra-framework/util
echo "y" | bash dev_setup.sh
echo ""

echo -e "\e[1m\e[32m2. Building libra binary files.\e[0m"

sleep 2
echo ""
cd ~/libra-framework
cargo build --release -p libra
sudo cp target/release/libra ~/.cargo/bin
version libra
echo ""

echo -e "\e[1m\e[32m3. Generating account config files.\e[0m"

sleep 2
echo ""
rm -rf ~/.libra/data &> /dev/null
mkdir ~/.libra &> /dev/null; mkdir ~/.libra/genesis &> /dev/null
cp -f ~/github_token.txt ~/.libra &> /dev/null
echo "Do you want to generate new wallet? (y/n)"
read -p "y/n : " user_input
if [[ $user_input == "y" ]]; then
    echo ""
    libra wallet keygen
else
    libra config validator-init
fi
libra config fullnode-init
echo ""

echo -e "\e[1m\e[32m4. Downloading network config files.\e[0m"

sleep 2
echo ""
cd ~/.libra/genesis
rm * &> /dev/null
wget https://github.com/AlanYoon71/0L_Network/raw/main/genesis.blob
wget https://github.com/AlanYoon71/0L_Network/raw/main/waypoint.txt
wget https://github.com/AlanYoon71/0L_Network/raw/main/genesis_balances.json
cd ~/.libra
rm *.json &> /dev/null
wget https://raw.githubusercontent.com/0LNetworkCommunity/v7-hard-fork-ceremony/main/artifacts/state_epoch_79_ver_33217173.795d.json
wget https://raw.githubusercontent.com/0LNetworkCommunity/v7-hard-fork-ceremony/main/artifacts/drop_list.json
wget https://github.com/AlanYoon71/0L_Network/raw/main/migration_sanitized.json
echo ""

echo -e "\e[1m\e[32m5. Updating network config files.\e[0m"

sleep 2
echo ""
libra config fix --force-url https://rpc.openlibra.space:8080
sed -i 's/testnet/mainnet/g' ~/.libra/libra-cli-config.yaml
echo "~/.libra/libra-cli-config.yaml updated."
echo ""
operator_update=$(grep full_node_network_public_key ~/.libra/public-keys.yaml)
sed -i "s/full_node_network_public_key:.*/$operator_update/" ~/.libra/operator.yaml &> /dev/null
sed -i 's/~$//' ~/.libra/operator.yaml &> /dev/null
echo "If you have VFN now, input your VFN IP address."
echo "If you don't have VFN yet, just enter."
echo ""
read -p "VFN IP address : " vfn_ip
echo ""
if [[ -z $vfn_ip ]]; then
    echo "You need to set up VFN later for 0l network's stability and security."
    ip_update=$(grep "  host:" ~/.libra/operator.yaml)
    echo "$ip_update" >> ~/.libra/operator.yaml
    echo ""
else
    echo "  host: $vfn_ip" >> ~/.libra/operator.yaml
fi
port_update=$(grep "  port:" ~/.libra/operator.yaml)
port_update=$(echo "$port_update" | sed 's/6180/6182/')
echo "$port_update" >> ~/.libra/operator.yaml
echo "~/.libra/operator.yaml updated."
echo ""

echo -e "\e[1m\e[32m6. Setting firewall and running libra with tmux.\e[0m"

sleep 2
echo ""
sudo ufw enable
sudo ufw allow 3000; sudo ufw allow 6180; sudo ufw allow 6181
tmux send-keys -t node:0 "exit" C-m &> /dev/null && session="node"
tmux new-session -d -s $session &> /dev/null
window=0
tmux rename-window -t $session:$window 'node'
echo ""
echo "Validator started."
tmux send-keys -t node:0 "RUST_LOG=info libra node" C-m
echo ""

animation() {
    local status="$1" # First argument: Initial status
    local command="$2" # Second argument: Command to execute
    local dots="."

    while :; do
        for (( i = 0; i < 10; i++ )); do
            echo -ne "$status $dots\033[K" # Display status variable
            sleep 0.2
            echo -en "\r"
            dots=".$dots"
        done
        dots="." # Reset dots counter
    done &
    local animation_pid=$! # Capture the PID of the background process

    eval "$command"

    kill $animation_pid # Stop the animation
    status=" Done" # Change status to "Done"
    echo -e "$status \e[1m\e[32m ✓\e[0m"
}

animation "Checking sync status now" "sleep 10 && SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'` && sleep 50 && SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`"

if [[ $SYNC1 -eq $SYNC2 ]]
then
    echo ""
    echo "Validator can't sync. Installation failed!"
    echo "Validator can't sync. Installation failed!"
    echo ""
    echo "Exiting script..."
    echo ""
    sleep 2
    exit
fi
echo ""
echo "Validator is running and syncing now! Installed successfully."
echo ""

echo -e "\e[1m\e[32m7. Registering with the validator universe.\e[0m"

sleep 2
echo ""
libra txs validator register
#libra txs validator update
while true; do
    echo "How much would you like to bid value? (0.01 ~ 1.1)"
    echo "Please check the lowest bid in the previous epoch."
    read -p "bid value : " bid_value
    echo ""
    echo "Your bid value is $bid_value."
    echo ""
    echo "Did you enter it correctly?(y/n)"
    read -p "y/n : " user_input
    if [[ $user_input == "y" ]]; then
        echo ""
        libra txs validator pof --bid-pct $bid_value --expiry 1000
        echo "If your txs fails, wait until catch-up completes and retry."
        break
    fi
done
echo ""

echo -e "\e[1m\e[32m8. Check your node status.\e[0m"

sleep 2
echo ""
tmux ls
echo ""
echo "Check your tmux sessions."
echo ""
curl -s localhost:8080/v1/ | jq
sleep 3
echo ""

echo "Done."
echo ""
