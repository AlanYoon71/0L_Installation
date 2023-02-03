#!/bin/bash
clear
echo ""
echo "=============================="
echo ""
echo "Script by  //-\ ][_ //-\ ][\[ ";
echo ""
echo "=============================="
echo ""
cd ~
echo -e "\e[1m\e[32m0. Wiping user \"node\" and files for preventing confliction. \e[0m"
echo "===================="
echo ""
sleep 2
userdel node &> /dev/null ; rm -rf /home/node &> /dev/null ;
sleep 3
echo -e "\e[1m\e[32m1. Installing dependencies.. \e[0m"
echo "===================="
echo ""
sleep 2
apt install -y git vim zip unzip bc jq build-essential cmake clang llvm libgmp-dev secure-delete pkg-config libssl-dev lld tmux
echo ""
echo -e "\e[1m\e[32m2. Installing required linux packages.. \e[0m"
echo "===================="
echo ""
sleep 2
curl -sL https://raw.githubusercontent.com/OLSF/libra/main/ol/util/setup.sh | bash
echo ""
echo "All required linux packages installed."
echo ""
echo ""
echo -e "\e[1m\e[32m3. Compiling 0l binary files.. \e[0m"
echo "===================="
echo ""
echo "This script includes genesis mining and tower, so it takes 1 hour more entirely until all processes completed, so be patient, please."
echo ""
sudo useradd node -m -s /bin/bash
\cp -f ./0l_tmux.sh /home/node
chmod +x /home/node/0l_tmux.sh
chmod go+rw /home/node/0l_tmux.sh
sudo -u node /home/node/0l_tmux.sh &&
CUR_DATE=`date +%Y%m%d` &&
mkdir -p /root/0l_config_backup/"$CUR_DATE" &> /dev/null ;
\cp -f /home/node/.0L/0L.toml /root/0l_config_backup/$CUR_DATE &> /dev/null ;
\cp -f /home/node/.0L/account.json /root/0l_config_backup/$CUR_DATE &> /dev/null ;
\cp -f /home/node/.0L/key_store.json /root/0l_config_backup/$CUR_DATE &> /dev/null ;
\cp -f /home/node/.0L/vdf_proofs/proof_0.json /root/0l_config_backup/$CUR_DATE &> /dev/null ;
sleep 1
echo ""
rm /home/node/bin/keygen.txt &> /dev/null ; rm /home/node/bin/waylength.txt &> /dev/null ; rm /home/node/bin/waypoint.txt &> /dev/null ; rm /home/node/bin/WAYPOINT.txt &> /dev/null ; rm /home/node/bin/update_check.txt &> /dev/null ;
sleep 2
echo -e "Your config files were saved into [\e[1m\e[32m /root/0l_config_backup/$CUR_DATE \e[0m] directory. There's no mnemonic info."
echo ""
echo ""
echo -e "\e[1m\e[32mDone! \e[0m"
echo ""
echo ""