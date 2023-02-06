#!/bin/bash
clear
echo ""
echo "=============================="
echo ""
echo "Script by  //-\ ][_ //-\ ][\[ ";
echo ""
echo "=============================="
echo ""
echo -e "\e[1m\e[32m0. Wiping user \"node\" and files for preventing confliction. \e[0m"
echo "===================="
echo ""
sudo pgrep -f node | sudo xargs kill &> /dev/null ; sleep 1 ; sudo pgrep -f node | sudo xargs kill &> /dev/null ;
sleep 1
sudo userdel node &> /dev/null && sudo rm -rf /home/node &> /dev/null && sudo rm $HOME/0L_Fullnode_installation &> /dev/null
sleep 1
echo "Wiped all."
echo ""
echo ""
sleep 2
echo -e "\e[1m\e[32m1. Installing dependencies.. \e[0m"
echo "===================="
echo ""
sleep 2
sudo apt install -y git vim zip unzip bc jq build-essential cmake clang llvm libgmp-dev secure-delete pkg-config libssl-dev lld tmux
echo ""
echo -e "\e[1m\e[32m2. Installing required linux packages.. \e[0m"
echo "===================="
echo ""
sleep 2
sudo curl -sL https://raw.githubusercontent.com/OLSF/libra/main/ol/util/setup.sh | bash
echo ""
echo "All required linux packages installed."
echo ""
echo ""
echo -e "\e[1m\e[32m3. Compiling 0l binary files.. \e[0m"
echo "===================="
echo ""
echo "This script includes genesis mining and tower, so it takes 1 hour more entirely until all processes completed, so be patient, please."
echo ""
sudo useradd node -m -s /bin/bash &&
sleep 2
sudo \cp -f ./0l_tmux.sh /home/node &> /dev/null ; sudo \cp -f ./autopay_batch.json /home/node &> /dev/null ;
sleep 2
sudo chmod +x /home/node/0l_tmux.sh
sudo chmod go+rw /home/node/0l_tmux.sh
sudo -u node /home/node/0l_tmux.sh &&
CUR_DATE=`date +%Y%m%d` &&
sudo mkdir -p $HOME/0l_config_backup/"$CUR_DATE" &> /dev/null ;
sudo \cp -f /home/node/.0L/0L.toml $HOME/0l_config_backup/$CUR_DATE &> /dev/null ;
sudo \cp -f /home/node/.0L/account.json $HOME/0l_config_backup/$CUR_DATE &> /dev/null ;
sudo \cp -f /home/node/.0L/key_store.json $HOME/0l_config_backup/$CUR_DATE &> /dev/null ;
sudo \cp -f /home/node/.0L/vdf_proofs/proof_0.json $HOME/0l_config_backup/$CUR_DATE &> /dev/null ;
sleep 1
echo ""
cd $HOME &&
sudo rm -r 0L_Fullnode_installation &> /dev/null ;
sleep 2
sudo rm /home/node/bin/keygen.txt &> /dev/null ; sudo rm /home/node/bin/waylength.txt &> /dev/null ; sudo rm /home/node/bin/waypoint.txt &> /dev/null ; sudo rm /home/node/bin/WAYPOINT.txt &> /dev/null ; sudo rm /home/node/bin/update_check.txt &> /dev/null ;
sleep 2
echo -e "Your config files were saved into [\e[1m\e[32m $HOME/0l_config_backup/$CUR_DATE \e[0m] directory. There's no mnemonic info."
echo ""
echo ""
echo "Done!"
echo ""
echo ""