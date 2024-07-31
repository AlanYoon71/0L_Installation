#!/bin/bash
echo ""
if [ -f $HOME/.libra/operator.yaml ]
then
    ID=$(grep -Po '(?<=full_node_network_public_key: "0x).*' $HOME/.libra/public-keys.yaml | sed 's/"$//')
    sleep 0.2
    IP=$(hostname -I | awk '{print $1}')
    sleep 0.5
    echo -en "\n"
    echo -en "\n"
    echo -e "\e[1m\e[33mYour Seed Format \e[0m" 
    echo "=================================================================================================================================="
    echo -e '
  seed_addrs:
    '$ID':
    - "/ip4/'$IP'/tcp/6182/noise-ik/0x'$ID'/handshake/0"'
    echo ""
    echo "=================================================================================================================================="
    echo -en "\n"
else
    echo -e "\e[1m\e[32mCan't find 'operator.yaml' file: "$HOME/.libra"  \e[0m" 
fi
echo ""