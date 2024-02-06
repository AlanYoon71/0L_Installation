#!/bin/bash

echo ""
echo -e "\e[1m\e[32m1. Prepare environment and build for libra.\e[0m"
echo ""
sleep 2
cd ~
apt update
apt install sudo
sudo apt install -y nano git wget ufw curl tmux bc sysstat jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && . .bashrc
mkdir ~/.libra &> /dev/null;
if [ -d ~/libra-framework ]; then
    cd ~/libra-framework && git fetch && git pull
else
    git clone https://github.com/0LNetworkCommunity/libra-framework && cd ~/libra-framework
    bash ./util/dev_setup.sh -t && source ~/.bashrc
    cd ~/libra-framework
fi

cargo build --release -p libra && sudo cp -f ~/libra-framework/target/release/libra* ~/.cargo/bin/
echo ""
echo "Building done."
echo ""
sleep 1
echo -e "\e[1m\e[32m2. Keygen for wallet.\e[0m"
echo ""
sleep 1

echo "Do you want to keygen for your new wallet? (y/n)"
read -p "y/n : " user_input
if [[ $user_input == "y" ]]; then
    echo ""
    new=1
    echo -e "\e[1m\e[32m2. Keygen new wallet.\e[0m"
    libra wallet keygen
    echo ""
    echo -e "\e[1m\e[32m3. Initialize validator config.\e[0m"
    echo ""
elif [[ $user_input == "n" ]]; then
    echo ""
    echo -e "\e[1m\e[32m3. Initialize validator config.\e[0m"
    echo ""

fi
libra config validator-init
libra config fullnode-init
libra config fix --force-url https://rpc.openlibra.space:8080
echo ""
echo -e "\e[1m\e[32m4. Restore db for fast catch-up.\e[0m"
echo ""
sleep 1

pip install gdown &> /dev/null && pip install --upgrade gdown &> /dev/null
cd ~ && gdown --id 1e7c7Tu4v6EeuST5AnIR8s7LcllbYUMxv && gdown --id 1_VD2PrnSbpNw6ovC0N2rbH2_jTysWj0p
tar -xvf data_04Feb.zip && rm data_04Feb.zip* && tar -xvf genesis_04Feb.zip && rm genesis_04Feb.zip*
rm -rf ~/.libra/data; rm -rf ~/.libra/genesis; rm ./data_04Feb/*.json;
mv ./data_04Feb ~/.libra/data && mv ./genesis_04Feb ~/.libra/genesis

echo ""
operator_update=$(grep full_node_network_public_key ~/.libra/public-keys.yaml)
sed -i "s/full_node_network_public_key:.*/$operator_update/" ~/.libra/operator.yaml &> /dev/null
sed -i 's/~$//' ~/.libra/operator.yaml &> /dev/null
ip_update=$(grep "  host:" ~/.libra/operator.yaml)
echo "$ip_update" >> ~/.libra/operator.yaml
port_update=$(grep "  port:" ~/.libra/operator.yaml)
port_update=$(echo "$port_update" | sed 's/6180/6182/')
echo "$port_update" >> ~/.libra/operator.yaml
echo ""
echo "Fullnode config in operator.yaml updated."

# if [ -d ~/epoch-archive-mainnet ]; then
#     cd ~/epoch-archive-mainnet && make wipe-db && make restore-all
#     cd ~
# else
#     git clone https://github.com/0LNetworkCommunity/epoch-archive-mainnet; cd ~/epoch-archive-mainnet && make bins && make restore-all
#     cd ~
# fi

echo ""
echo -e "\e[1m\e[32m5. Run libra node.\e[0m"
echo ""
sudo ufw enable &> /dev/null;
sudo ufw allow ssh &> /dev/null;sudo ufw allow 6180 &> /dev/null;sudo ufw allow 6181 &> /dev/null;sudo ufw allow 6182 &> /dev/null;sudo ufw allow 9100 &> /dev/null;sudo ufw allow 8080 &> /dev/null;
sleep 2
PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
session="node"
tmux new-session -d -s $session &> /dev/null
window=0
tmux rename-window -t $session:$window 'node' &> /dev/null
PIDCHECK=$(pgrep libra)
if [[ -z $PIDCHECK ]]
then
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml" C-m
    sleep 30
fi
PIDCHECK=$(pgrep libra)
if [[ -z $PIDCHECK ]]
then
    echo "Fullnode stopped. Install failed!!!"
    echo "Fullnode stopped. Install failed!!!"
    echo ""
    echo "Exiting script..."
    PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
    echo ""
    sleep 3
    exit
else
    echo -e "\e[1m\e[32mFullnode is running now. Good job!\e[0m"
    echo ""
    sleep 2
    echo "Wait until your node is fully synced."
    echo ""
    sleep 3
    watch 'curl localhost:8080/v1/ | jq'
    echo ""
    if [[ -z $new ]]
    then
        :
    else
        address=`grep -oP '(?<=account: )\w+' libra.yaml`
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
        echo "   Command : libra txs validator pof --bid-pct 0.5 --expiry 1000"
        echo "============================================================="
        echo ""
    fi
    sleep 2
    echo -e "\e[1m\e[32m6. Run delay tower.\e[0m"
    echo ""
    session="tower"
    tmux new-session -d -s $session &> /dev/null
    window=0
    tmux rename-window -t $session:$window 'tower' &> /dev/null
    tmux send-keys -t tower:0 "libra tower zero && libra tower start" C-m
    tmux attach -t tower
fi
