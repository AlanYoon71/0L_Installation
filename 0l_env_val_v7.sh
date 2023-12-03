#!/bin/bash
clear
echo ""
echo "=====================================";
echo ""
echo "Created by Alan Yoon #2149 0L Network";
echo ""
echo "=====================================";
echo "                           2023-11-24"
echo ""
echo "This script was created only for installing \"0L network validator(fullnode mode)\" and \"ubuntu 20.04\" LTS environment."
sleep 2
echo ""
echo "If you get more than 8 VDF proofs and 4 vouchers, you can convert mode fullnode to validator."
sleep 2
echo ""
echo "Script starts! Maybe it'll be over in 1 hour. It's up to your CPU performance."
sleep 2
echo ""
echo ""
echo -e "\e[1m\e[32m0. cleanup of previous binaries or testnet data. \e[0m"
echo "===================="
echo ""
sleep 1
# sudo pgrep -f node | sudo xargs kill &> /dev/null ; sleep 1 ; sudo pgrep -f node | sudo xargs kill &> /dev/null ;
# sleep 1
# sudo userdel node &> /dev/null ; sudo rm -rf /home/node &> /dev/null ; sudo rm $HOME/0L_Installation &> /dev/null
mkdir ~/yaml_backup > /dev/null; cp -f ~/.libra/*.yaml ~/yaml_backup > /dev/null; rm -rf ~/.libra > /dev/null; rm -rf ~/libra-framework > /dev/null; rm -f /usr/bin/libra > /dev/null; rm -rf /usr/local/bin/lira > /dev/null; rm -f ~/.cargo/bin/libra > /dev/null; cp ~/github_token.txt ~/.libra
sleep 2
echo "Wiped all. All your yaml files have been moved to ~/yaml_backup."
echo ""
echo ""
sleep 2
echo -e "\e[1m\e[32m1. Fetch source and verify commit hash. \e[0m"
echo "===================="
echo ""
sleep 1
# sudo apt-get update && apt update
# sleep 1
# sudo apt-get install -y sudo curl git vim sysstat zip unzip daemontools bc jq build-essential cmake clang llvm libgmp-dev secure-delete pkg-config libssl-dev lld tmux
cd ~ && git clone https://github.com/0LNetworkCommunity/libra-framework && cd ~/libra-framework && git fetch --all && git checkout release-6.9.0-rc.10
echo ""
git log -n 1 --pretty=format:"%H"
echo ""
echo ""
echo -e "\e[1m\e[32m2. Build and install the libra binaries. \e[0m"
echo "===================="
echo ""
sleep 2
# sudo curl -sL https://raw.githubusercontent.com/OLSF/libra/main/ol/util/setup.sh | bash
mkdir ~/.libra && cd ~/libra-framework/tools/genesis && make install
echo ""
echo "All required libra binaries have been installed."
echo ""
sleep 1
echo ""
echo -e "\e[1m\e[32m3. Initialize validator account. \e[0m"
echo "===================="
echo ""
#echo "This script includes genesis mining and tower, so it takes 1 hour more entirely until all processes completed, so be patient, please."
libra config validator-init && sleep 1 && grep 'account_address' ~/.libra/public-keys.yaml
echo ""
