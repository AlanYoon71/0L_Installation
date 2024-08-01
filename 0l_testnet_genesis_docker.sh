#!/bin/bash

echo ""
# echo "";
echo "    ██████╗ ██████╗ ███████╗███╗   ██╗     ██╗     ██╗██████╗ ██████╗  █████╗  ";        
echo "   ██╔═══██╗██╔══██╗██╔════╝████╗  ██║     ██║     ██║██╔══██╗██╔══██╗██╔══██╗ ";        
echo "   ██║   ██║██████╔╝█████╗  ██╔██╗ ██║     ██║     ██║██████╔╝██████╔╝███████║ ";        
echo "   ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║     ██║     ██║██╔══██╗██╔══██╗██╔══██║ ";        
echo "   ╚██████╔╝██║     ███████╗██║ ╚████║     ███████╗██║██████╔╝██║  ██║██║  ██║ ";        
echo "    ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝     ╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ";
echo -e "                  A PERMISSIONLESS, TRANSPARENT, COMMUNITY-DRIVEN PROJECT ✊🔆";
echo "";
echo "         ████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗ ";
echo "         ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝ ";
echo "            ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║    ";
echo "            ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║    ";
echo "            ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║    ";
echo "            ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝    ";
echo "";
echo "             ██████╗ ███████╗███╗   ██╗███████╗███████╗██╗███████╗ ";
echo "            ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔════╝██║██╔════╝ ";
echo "            ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ███████╗██║███████╗ ";
echo "            ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ╚════██║██║╚════██║ ";
echo "            ╚██████╔╝███████╗██║ ╚████║███████╗███████║██║███████║ ";
echo "             ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚══════╝ ";
echo "";

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

# content="alice    158.247.247.207
# bob      172.17.0.3
# carol    172.17.0.4
# dave     172.17.0.5"

# echo "$content" > testnet_iplist.txt

if [ -d "$HOME/libra-framework" ]; then
    cd ~/libra-framework
else
    git clone https://github.com/0LNetworkCommunity/libra-framework
    cd ~/libra-framework
fi
sudo apt update && sudo apt install -y nano bc tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev net-tools
rustup default 1.74.0
sed -i 's/1.70.0/1.74.0/g' ~/libra-framework/rust-toolchain
sudo apt install curl; curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; source ~/.bashrc
echo "Updating cargo-nextest.."
sleep 1
export PATH="$HOME/.cargo/bin:$PATH"; rustup update; rustup default stable; cargo install cargo-nextest; cargo nextest --version
echo "Checking and rebuilding packages.."
sleep 1
sudo apt install curl; curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y; source ~/.bashrc

echo ""
echo "Input libra-framework release version(x.y.z)."
read -p "release : " release_version
echo ""
echo "libra-framework release version for setup is $release_version."
echo ""


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
cd ~/libra-framework
rustup default 1.74.0
sed -i 's/1.70.0/1.74.0/g' ~/libra-framework/rust-toolchain
sudo apt install make
sudo rm -rf ~/.libra && mkdir ~/.libra && cd ~/libra-framework/tools/genesis && make install && source ~/.bashrc
echo ""
cd ~
echo "Updating cargo-nextest.."
sleep 1
export PATH="$HOME/.cargo/bin:$PATH"; rustup update; rustup default stable; cargo install cargo-nextest; cargo nextest --version
echo ""
echo "Checking and rebuilding packages.."
sleep 1
cd ~/libra-framework/tools/genesis; make install; source ~/.bashrc
echo ""
libra version
echo ""


echo -e "\e[1m\e[32m3. Generating account config files.\e[0m"

sleep 2
echo ""
sudo rm -rf ~/.libra/data &> /dev/null
mkdir ~/.libra &> /dev/null; mkdir ~/.libra/genesis &> /dev/null
sudo cp -f ~/github_token.txt ~/.libra &> /dev/null
sudo cp -f ~/testnet_iplist.txt ~/.libra &> /dev/null
echo "export PATH=$PATH:$HOME/.cargo/bin" >> ~/.bashrc && . ~/.bashrc
# echo "Do you want to generate new wallet? (y/n)"
# read -p "y/n : " user_input
# if [[ $user_input == "y" ]]; then
#     echo ""
#     libra wallet keygen
# else
#     :
# fi
echo ""
wget https://raw.githubusercontent.com/0LNetworkCommunity/v7-hard-fork-ceremony/main/artifacts/state_epoch_79_ver_33217173.795d.json -P $HOME/.libra/
IP=$(hostname -I | awk '{print $1}')
me=$(awk -v ip="$IP" '$2 == ip {print $1}' $HOME/testnet_iplist.txt)
libra genesis testnet -m "$me" $(awk '{printf "-i %s ", $2}' $HOME/testnet_iplist.txt) --json-legacy $HOME/.libra/state_epoch_79_ver_33217173.795d.json

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

cp -f ~/.libra/validator.yaml ~/.libra/validator.yaml.bak && sed -i '/^[0-9a-f]\{64\}:$/d; /^[[:space:]]*- \/ip4\/[0-9.]\+\/tcp\/6182\/noise-ik\/0x[0-9a-f]\{64\}\/handshake\/0$/d' ~/.libra/validator.yaml
sleep 0.2
cp ~/.libra/validator.yaml ~/.libra/validator.yaml.bak && sed -i '/seed_addrs:/,/seeds:/{ /seed_addrs:/b; /seeds:/b; d; }' ~/.libra/validator.yaml
sleep 0.2
cp ~/.libra/validator.yaml ~/.libra/validator.yaml.bak && sed -i '/seed_addrs:/{/seed_addrs: *{}/!{a\      493847429420549694a18a82bc9b1b1ce21948bbf1cd4c5cee9ece0fb8ead50a:\n      - "/ip4/158.247.247.207/tcp/6182/noise-ik/0x493847429420549694a18a82bc9b1b1ce21948bbf1cd4c5cee9ece0fb8ead50a/handshake/0"
}}' ~/.libra/validator.yaml
echo "~/.libra/validator.yaml updated with testnet seed."
echo ""
echo "Done."
echo ""
