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
echo "All required linux packages installed."
echo ""
echo ""
echo -e "\e[1m\e[32m3. Compiling 0l binary files.. \e[0m"
echo "===================="
echo ""
echo "This script includes genesis mining and tower, so it takes 1 hour more entirely until all processes completed, so be patient, please."
echo ""
sudo useradd node -m -s /bin/bash
cp ./0l_tmux.sh /home/node
chmod +x /home/node/0l_tmux.sh
chmod go+rw /home/node/0l_tmux.sh
sudo -u node /home/node/0l_tmux.sh &&
CUR_DATE=`date +%Y%m%d` &&
mkdir -p /root/0l_config_backup/"$CUR_DATE" &&
cp /home/node/.0L/0L.toml /root/0l_config_backup/$CUR_DATE &&
cp /home/node/.0L/account.json /root/0l_config_backup/$CUR_DATE &&
cp /home/node/.0L/key_store.json /root/0l_config_backup/$CUR_DATE &&
cp /home/node/.0L/vdf_proofs/proof_0.json /root/0l_config_backup/$CUR_DATE &&
echo ""
echo -e "Your config files backuped in \e[1m\e[32m[ /root/0l_config_backup/$CUR_DATE ] \e[0mdirectory. There's no mnemonic info."
echo ""
sleep 2
echo "So if you didn't write down your mnemonic yet, goto running sessions and check screen."
echo ""
echo ""
sleep 2
echo -e "\e[1m\e[32mDone!! \e[0m"
echo ""