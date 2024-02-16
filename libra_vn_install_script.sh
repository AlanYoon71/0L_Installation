#!/bin/bash

clear
echo ""
echo "";
echo " ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░▒▓███████▓▒░       ░▒▓█▓▒░      ░▒▓█▓▒░▒▓███████▓▒░░▒▓███████▓▒░ ░▒▓██████▓▒░  ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓███████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo " ░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓████████▓▒░▒▓█▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ";
echo "";
echo ""
echo ""
echo -e "\e[1m\e[32m1. Prepare environment for libra validator setup.\e[0m"
echo ""
sleep 3
cd ~
apt update
apt install sudo
sudo apt install -y nano git wget ufw curl tmux bc sysstat jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && echo "PATH=$PATH:$HOME/.cargo/bin:$HOME/.cargo/env" >> ~/.bashrc && . .bashrc
mkdir ~/.libra &> /dev/null;
echo ""
echo -e "\e[1m\e[32m2. Download libra framework source and git pull.\e[0m"
echo ""
sleep 3
if [ -d ~/libra-framework ]; then
    cd ~/libra-framework && git fetch && git pull
else
    git clone https://github.com/0LNetworkCommunity/libra-framework && cd ~/libra-framework
    bash ./util/dev_setup.sh -t && source ~/.bashrc
    cd ~/libra-framework && git fetch && git pull
fi
echo ""
echo -e "\e[1m\e[32m3. Build libra binary files.\e[0m"
echo ""
sleep 3
cargo build --release -p libra && sudo cp -f ~/libra-framework/target/release/libra* ~/.cargo/bin/
source ~/.bashrc
echo ""
echo "Building done."
echo ""
sleep 3
echo -e "\e[1m\e[32m4. Keygen for wallet.\e[0m"
echo ""
sleep 3

echo "Do you want to keygen for your new wallet? (y/n)"
read -p "y/n : " user_input
if [[ $user_input == "y" ]]; then
    echo ""
    new=1
    libra wallet keygen
elif [[ $user_input == "n" ]]; then
    :
fi
echo ""
echo -e "\e[1m\e[32m5. Initialize validator and fullnode configs.\e[0m"
echo ""
sleep 3
libra config validator-init
echo ""
libra config fullnode-init
if [ $? -ne 0 ]
then
    echo "base:
    role: 'full_node'
    data_dir: '/root/.libra/data'
    waypoint:
        from_file: '/root/.libra/genesis/waypoint.txt'

    state_sync:
        state_sync_driver:
            # do a fast sync with DownloadLatestStates
            # bootstrapping_mode: ExecuteOrApplyFromGenesis
            bootstrapping_mode: DownloadLatestStates
            continuous_syncing_mode: ExecuteTransactionsOrApplyOutputs

    execution:
    genesis_file_location: '/root/.libra/genesis/genesis.blob'

    full_node_networks:
    - network_id: 'public'
    listen_address: '/ip4/0.0.0.0/tcp/6182'
    seed_addrs:
        cb7e573123b67b0bb957d23f0d11c65b0b5438815b3750461c3815d507fb5649:
        - "/ip4/73.181.115.53/tcp/6182/noise-ik/0xcb7e573123b67b0bb957d23f0d11c65b0b5438815b3750461c3815d507fb5649/handshake/0"
        1017ce1abc30e356660b8b0542275f2fb4373b5f8a82b7800a5b3fdf718ae55f:
        - "/ip4/70.15.242.6/tcp/6182/noise-ik/0x1017ce1abc30e356660b8b0542275f2fb4373b5f8a82b7800a5b3fdf718ae55f/handshake/0"
        619898b2f99fba7b25fae35e3eab03164d7d9ce0d10abe8f6ceae9a43ffa1c34:
        - "/ip4/65.109.80.179/tcp/6182/noise-ik/0x619898b2f99fba7b25fae35e3eab03164d7d9ce0d10abe8f6ceae9a43ffa1c34/handshake/0"
        bc2d1a55f90dfd27e4ef871285f13386997aecf609a3c4d4c4527efc9b2d193e:
        - "/ip4/94.130.22.86/tcp/6182/noise-ik/0xbc2d1a55f90dfd27e4ef871285f13386997aecf609a3c4d4c4527efc9b2d193e/handshake/0"
        3b315502851df6d3004c69cf17714559d2407e28477b622d4e28c7b876859d0a:
        - "/ip4/144.76.104.93/tcp/6182/noise-ik/0x3b315502851df6d3004c69cf17714559d2407e28477b622d4e28c7b876859d0a/handshake/0"
        46b3705ebeeb469dd980210ace3462a91320249d37e90d1279a9a9df94995278:
        - "/ip4/136.243.59.175/tcp/6182/noise-ik/0x46b3705ebeeb469dd980210ace3462a91320249d37e90d1279a9a9df94995278/handshake/0"
        9ac157ee324e4129c9edac7ba5eca70af299929ae8c0d7362f4e6c75a7ac447e:
        - "/ip4/104.248.94.195/tcp/6182/noise-ik/0x9ac157ee324e4129c9edac7ba5eca70af299929ae8c0d7362f4e6c75a7ac447e/handshake/0"

    api:
    enabled: true
    address: '0.0.0.0:8080'" > ~/.libra/fullnode.yaml
    sleep 2
    sed -e "s/\/root\//$(echo $HOME | sed 's/\//\\\//g')\//g" ~/.libra/fullnode.yaml > temp_file
    mv -f temp_file ~/.libra/fullnode.yaml
    pip install gdown &> /dev/null && pip install --upgrade gdown &> /dev/null
    cd ~ && gdown --id 1_VD2PrnSbpNw6ovC0N2rbH2_jTysWj0p && tar -xvf genesis_04Feb.zip && rm genesis_04Feb.zip* && rm -rf ~/.libra/genesis; mv ./genesis_04Feb ~/.libra/genesis
    echo ""
    echo "Fullnode config and waypoint fixed successfully."
    echo ""
    sleep 3
fi

libra config fix --force-url https://rpc.openlibra.space:8080
echo ""
echo -e "\e[1m\e[32m6. Restore db for fast catch-up.\e[0m"
echo ""
sleep 3
echo ""

cd ~
if [ -d ~/epoch-archive-mainnet ]
then
    cd ~/epoch-archive-mainnet
else
    git clone https://github.com/0LNetworkCommunity/epoch-archive-mainnet
    cd ~/epoch-archive-mainnet
fi
make bins
make restore-all
if [ $? -ne 0 ]
then
    pip install gdown &> /dev/null && pip install --upgrade gdown &> /dev/null
    cd ~ && gdown --id 1_VD2PrnSbpNw6ovC0N2rbH2_jTysWj0p && tar -xvf genesis_04Feb.zip && rm genesis_04Feb.zip* && rm -rf ~/.libra/genesis; mv ./genesis_04Feb ~/.libra/genesis
fi

operator_update=$(grep full_node_network_public_key ~/.libra/public-keys.yaml)
sed -i "s/full_node_network_public_key:.*/$operator_update/" ~/.libra/operator.yaml &> /dev/null
sed -i 's/~$//' ~/.libra/operator.yaml &> /dev/null

echo ""
echo ""
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
echo "Fullnode config in operator.yaml updated."
echo ""
echo -e "\e[1m\e[32m7. Run fullnode and check status.\e[0m"
sudo ufw enable &> /dev/null;
sudo ufw allow ssh &> /dev/null;sudo ufw allow 6180 &> /dev/null;sudo ufw allow 6181 &> /dev/null;sudo ufw allow 6182 &> /dev/null;sudo ufw allow 9100 &> /dev/null;sudo ufw allow 8080 &> /dev/null;
sleep 2
session="node"
tmux new-session -d -s $session &> /dev/null
window=0
tmux rename-window -t $session:$window 'node' &> /dev/null
echo ""
echo "Now start fullnode. Wait a moment(about 4 minutes) until the node stabilizes."
tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml" C-m
sleep 60
SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
sleep 120
SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
sleep 60
echo ""
echo "Checking fullnode's sync status..."
echo ""
if [[ $SYNC1 -eq $SYNC2 ]]
then
    tmux send-keys -t node:0 "exit" C-m &> /dev/null;
    sleep 5
    echo "Fullnode stopped!!"
    echo "Fullnode stopped!!"
    echo ""
    echo "It seems that your DB lacks integrity."
    echo "Downloading DB and genesis backup files from Alan’s Google Drive."
    echo ""
    sleep 3
    
    pip install gdown &> /dev/null && pip install --upgrade gdown &> /dev/null
    cd ~ && gdown --id 1e7c7Tu4v6EeuST5AnIR8s7LcllbYUMxv
    if [ $? -ne 0 ]
    then
        echo ""
        echo "Google Drive is currently busy, so recommend running this script again in 30 minutes."
        echo ""
        echo "Exiting script..."
        echo ""
        sleep 3
        exit
    fi
    gdown --id 1_VD2PrnSbpNw6ovC0N2rbH2_jTysWj0p
    if [ $? -ne 0 ]
    then
        echo ""
        echo "Google Drive is currently busy."
        echo ""
        echo "Wait 5minutes, please.."
        gdown --id 1_VD2PrnSbpNw6ovC0N2rbH2_jTysWj0p
        echo "Google Drive is currently busy, so recommend running this script again in 30 minutes."
        echo ""
        echo "Exiting script..."
        echo ""
        sleep 3
        exit
    fi
    tar -xvf data_04Feb.zip && rm data_04Feb.zip* && tar -xvf genesis_04Feb.zip && rm genesis_04Feb.zip*
    rm -rf ~/.libra/data; rm -rf ~/.libra/genesis; rm ./data_04Feb/*.json
    mv ./data_04Feb ~/.libra/data && mv ./genesis_04Feb ~/.libra/genesis
    
    echo ""
    echo "Now start fullnode again. Wait a moment(about 2 minutes) until the node stabilizes."
    session="node"
    tmux new-session -d -s $session &> /dev/null
    window=0
    tmux rename-window -t $session:$window 'node' &> /dev/null
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml" C-m
    sleep 60
    SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
    sleep 120
    SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
    sleep 60
    if [[ $SYNC1 -eq $SYNC2 ]]
    then
        echo ""
        echo "Fullnode stopped!! Install failed!!"
        echo "Fullnode stopped!! Install failed!!"
        echo ""
        echo "Exiting script..."
        echo ""
        sleep 3
        exit
    fi
fi
echo ""
echo -e "\e[1m\e[32mFullnode is running now! Installed successfully.\e[0m"
echo ""
sleep 3

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
    echo "   Command : libra txs validator pof --bid-pct 0.1 --expiry 1000"
    echo "============================================================="
    echo ""
    sleep 5
fi

echo -e "\e[1m\e[32m8. Check your node status.\e[0m"
echo ""
sleep 3
tmux ls
echo ""
echo "Check your tmux sessions."
echo ""
curl -s localhost:8080/v1/ | jq
sleep 3
echo ""
echo "Done."
echo ""
