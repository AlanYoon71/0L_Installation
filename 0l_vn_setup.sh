#!/bin/bash

echo ""
echo "";
echo "     ██████╗ ██╗         ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗ ";
echo "    ██╔═████╗██║         ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝ ";
echo "    ██║██╔██║██║         ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝  ";
echo "    ████╔╝██║██║         ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗  ";
echo "    ╚██████╔╝███████╗    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗ ";
echo "     ╚═════╝ ╚══════╝    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ";
echo "";
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
sudo apt install -y nano wget git
if [[ -f $HOME/github_token.txt ]]
then
    :
else
    echo "github token is not found in $HOME directory."
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
            echo $token > $HOME/github_token.txt
            break
        fi
    done
fi
# if [ -d "$HOME/libra-framework" ]; then
#     cd ~/libra-framework
# else
#     git clone https://github.com/0LNetworkCommunity/libra-framework
#     cd ~/libra-framework
# fi
# sudo apt update && sudo apt install -y nano bc tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev net-tools
# rustup default 1.74.0
# sed -i 's/1.70.0/1.74.0/g' ~/libra-framework/rust-toolchain
# sudo apt install curl; curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; source ~/.bashrc
# echo "Updating cargo-nextest.."
# sleep 1
# export PATH="$HOME/.cargo/bin:$PATH"; rustup update; rustup default stable; cargo install cargo-nextest; cargo nextest --version
# echo "Checking and rebuilding packages.."
# sleep 1
# sudo apt install curl; curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; source ~/.bashrc
if [ -d "$HOME/libra-framework" ]; then
    export PATH="$HOME/.cargo/bin:$PATH" && rustup update && rustup default stable && cargo install cargo-nextest && cargo nextest --version
    cd ~/libra-framework
else
    git clone https://github.com/0LNetworkCommunity/libra-framework
fi
sudo apt update && sudo apt install -y bc tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev net-tools
cd ~/libra-framework
sudo apt install curl && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && source ~/.bashrc
cd ~
export PATH="$HOME/.cargo/bin:$PATH" && rustup update && rustup default stable && cargo install cargo-nextest && cargo nextest --version
cd ~/libra-framework
sudo apt install curl && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && source ~/.bashrc
while true; do
    echo ""
    echo "Input libra-framework release version(x.y.z)."
    read -p "release : " release_version
    echo ""
    echo "libra-framework release version for setup is $release_version."
    echo ""
    echo "Did you enter it correctly?(y/n)"
    read -p "y/n : " user_input
    if [[ $user_input == "y" ]]; then
        echo ""
        break
    fi
done
git fetch --all
git checkout -f release-$release_version
git pull
git log -n 1 --pretty=format:"%H"
cd ~/libra-framework/util
echo "y" | bash dev_setup.sh
echo ""

echo -e "\e[1m\e[32m2. Building libra binary files.\e[0m"

sleep 2
echo ""
export PATH="$HOME/.cargo/bin:$PATH";
cd ~/libra-framework
cargo build --release -p libra
sudo cp target/release/libra ~/.cargo/bin
echo ""
libra version
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
fi
libra config validator-init
libra config fullnode-init
echo ""

echo -e "\e[1m\e[32m4. Verifying the integrity of the network file.\e[0m"

sleep 2
echo ""
genesis_check=$(sha256sum ~/.libra/genesis/genesis.blob | awk '{print $1}')
if [[ "$genesis_check" == "ba1ae01d5fb4113f618a9deb3357db41d283299691eb1ae7c83982291e9c53f3" ]]
then
    echo -e "Current genesis.blob sha256sum: $genesis_check ..... \e[1m\e[32m ✓\e[0m"
    sleep 3
else
    echo -e "Correct genesis.blob sha256sum: ba1ae01d5fb4113f618a9deb3357db41d283299691eb1ae7c83982291e9c53f3"
    echo -e "Current genesis.blob sha256sum: $genesis_check ..... not matched."
    sleep 3
    wget -O ~/.libra/genesis/genesis.blob https://github.com/AlanYoon71/0L_Network/raw/main/genesis.blob
    genesis_check=$(sha256sum ~/.libra/genesis/genesis.blob | awk '{print $1}')
    if [[ "$genesis_check" == "ba1ae01d5fb4113f618a9deb3357db41d283299691eb1ae7c83982291e9c53f3" ]]
    then
        echo -e "Current genesis.blob sha256sum: $genesis_check ..... \e[1m\e[32m ✓\e[0m"
        sleep 3
    else
        echo -e "There's no correct genesis.blob file, installation failed."
        echo ""
        exit
    fi
fi
waypoint_check=$(cat ~/.libra/genesis/waypoint.txt)
if [[ "$waypoint_check" == "0:0b0947eb5327275bc7cfde3cb5c0cd03a0058e3c54c30ba962fbc90e97e664ce" ]]
then
    echo -e "Current waypoint: $waypoint_check ..... \e[1m\e[32m ✓\e[0m"
    sleep 3
else
    echo -e "Correct waypoint: 0:0b0947eb5327275bc7cfde3cb5c0cd03a0058e3c54c30ba962fbc90e97e664ce"
    echo -e "Current waypoint: $waypoint_check ..... not matched."
    sleep 3
    wget -O ~/.libra/genesis/waypoint.txt https://github.com/AlanYoon71/0L_Network/raw/main/waypoint.txt
    waypoint_check=$(cat ~/.libra/genesis/waypoint.txt)
    if [[ "$waypoint_check" == "0:0b0947eb5327275bc7cfde3cb5c0cd03a0058e3c54c30ba962fbc90e97e664ce" ]]
    then
        echo -e "Current waypoint: $waypoint_check ..... \e[1m\e[32m ✓\e[0m"
        sleep 3
    else
        echo "0:0b0947eb5327275bc7cfde3cb5c0cd03a0058e3c54c30ba962fbc90e97e664ce" > ~/.libra/genesis/waypoint.txt
        echo -e "Waypoint updated."
    fi
fi
echo ""

echo -e "\e[1m\e[32m5. Updating network config files.\e[0m"

sleep 2
echo ""
libra config fix --force-url https://rpc.openlibra.space:8080/v1
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
echo "You should copy your vfn.yaml and operator.yaml on the validator to your VFN if you have."
echo ""

echo -e "\e[1m\e[32m6. Setting firewall and running libra with tmux.\e[0m"

sleep 2
echo ""
sudo ufw allow 6180; sudo ufw allow 6181
echo "Your firewall rule(ufw) has changed to open 6180 and 6181 ports."
echo "checking tmux sessions."
tmux send-keys -t node:0 "exit" C-m
session="node"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'node'
echo ""
echo "Validator is getting ready to start."
tmux send-keys -t node:0 "RUST_LOG=info libra node" C-m
echo ""
sleep 10
echo "Validator started."
echo ""
SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`

animation() {
    local status="$1"
    local command="$2"
    local dots="."

    while :; do
        for (( i = 0; i < 10; i++ )); do
            echo -ne "$status $dots\033[K"
            sleep 0.2
            echo -en "\r"
            dots=".$dots"
        done
        dots="."
    done &
    local animation_pid=$!

    eval "$command"

    kill $animation_pid
    status=" Done"
    echo -e "$status \e[1m\e[32m ✓\e[0m"
}
animation "Checking sync status now" "sleep 80"
SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`

if [[ $SYNC1 -eq $SYNC2 ]]
then
    echo ""
    echo "It appears that validator is not syncing. Try again now.."
    echo "checking tmux sessions."
    tmux send-keys -t node:0 "exit" C-m
    session="node"
    tmux new-session -d -s $session
    window=0
    tmux rename-window -t $session:$window 'node'
    tmux send-keys -t node:0 "RUST_LOG=info libra node" C-m
    echo ""
    sleep 10
    echo "Validator restarted."
    echo ""
    SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`

    animation() {
        local status="$1"
        local command="$2"
        local dots="."

        while :; do
            for (( i = 0; i < 10; i++ )); do
                echo -ne "$status $dots\033[K"
                sleep 0.2
                echo -en "\r"
                dots=".$dots"
            done
            dots="."
        done &
        local animation_pid=$!

        eval "$command"

        kill $animation_pid
        status=" Done"
        echo -e "$status \e[1m\e[32m ✓\e[0m"
}
    animation "Checking sync status now" "sleep 80"
    SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`

    if [[ $SYNC1 -eq $SYNC2 ]]
    then
        echo "Validator can't sync. Installation failed!"
        echo "Validator can't sync. Installation failed!"
        echo ""
        echo "You can check log in tmux session named node."
        echo "Exiting script..."
        echo ""
        sleep 2
        exit
    fi
fi
echo ""
echo "Validator is running and syncing now! Installed successfully."
echo ""

echo -e "\e[1m\e[32m7. Registering with the validator universe.\e[0m"

sleep 2
echo ""
echo "If you haven't created a new wallet, you'll need to update the val-config later."
echo "< libra txs validator update >"
sleep 2
# while true; do
#     echo ""
#     echo "How much would you like to bid value? (0.01 ~ 1.1)"
#     echo "Please check the lowest bid in the previous epoch."
#     read -p "bid value : " bid_value
#     echo ""
#     echo "Your bid value is $bid_value."
#     echo ""
#     echo "Did you enter it correctly?(y/n)"
#     read -p "y/n : " user_input
#     if [[ $user_input == "y" ]]; then
#         echo ""
#         libra txs validator pof --bid-pct $bid_value --expiry 1000
#         echo "If your txs fails, wait until catch-up completes and retry."
#         break
#     fi
# done

# echo ""
# echo "Your bid value will be set as 0.001."
# echo ""
# libra txs validator pof --bid-pct 0.001 --expiry 1000
echo ""

echo -e "\e[1m\e[32m8. Check your node status.\e[0m"

sleep 2
echo ""
tmux ls
echo ""
echo "If you want to check log, attach a tmux session with command below."
echo "< tmux attach -t node >"
echo ""
curl -s localhost:8080/v1/ | jq
sleep 3
echo ""
echo "After Syncing completes, register or update your validator config with command as below if you need."
echo "And set your bidding percentage. If not fully synced, the transaction will fail. Please be patient."
echo "Register : <libra txs validator register>, Update : <libra txs validator update>"
echo "Bidding : <libra txs validator pof --bid-pct 0.1 --expiry 1000>"
echo ""
echo "Done."
echo ""
