#!/bin/bash
echo ""
echo -e "Right now, you should save the active validator set info into current directory with a name as \e[1m\e[33mpage_active_validator_set.txt\e[0m."
echo "You can get this info at https://0lexplorer.io/validators, just copy and save the entire top table. Are you ready? (y/n)"
read answer
if [ "$answer" == "y" ] ; then : ; else exit ; fi
echo ""
voting=`timeout 5s tail -f ~/.0L/logs/node/current | grep "broadcast to all peers"`
sleep 0.1
echo "$voting" > broadcast_log.txt
export TIME=`date +%Y-%m-%dT%H:%M:%S`
if [ -z "$voting" ]
then
    echo "$TIME [INFO] No broadcasting now."
else
    grep -oE '[[:xdigit:]]{32}' page_active_validator_set.txt | cut -d ' ' -f1 | sort | uniq > active_validator_set.txt
    sleep 0.1
    export set1=`cat active_validator_set.txt | wc -l`
    echo -e "$TIME [INFO] Voting addresses of nodes are broadcasted."
    echo -e "\e[5;32m================================\e[0m"
    echo "$voting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq
    echo "$voting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq > voting_address.txt
    echo -e "\e[5;32m================================\e[0m"
    total=`cat voting_address.txt | wc -l`
    sleep 0.1
    if [ -z "$total" ] ; then total=$set1 ; fi 
    votediff=`expr $set1 - $total`
    export rate=$(echo "scale=2; $total / $set1 * 100" | bc)
    echo "Total voting : $total nodes, Total in set : $set1 nodes"
    echo -e "Vote    Rate : $rate%, \e[1m\e[31m$votediff \e[0mnodes are not voting now."
    nonvoting=$(grep -vf voting_address.txt active_validator_set.txt)
    sleep 0.1
    export TIME=`date +%Y-%m-%dT%H:%M:%S`
    if [ -z "$nonvoting" ]
    then
        echo "$TIME [INFO] All validators in the set are voting now. Great!"
    else
        echo -e "$TIME [INFO] Non-voting addresses of nodes in the active validator set"
        echo -e "\e[5;31m================================\e[0m"
        echo "$nonvoting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq
        echo "$nonvoting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq > non-voting_address.txt
        echo -e "\e[5;31m================================\e[0m"
        total2=`cat non-voting_address.txt | wc -l`
        echo -e "Total non-voting : \e[1m\e[31m$total2 \e[0mnodes, Total in set : $set1 nodes"
        if [ "$votediff" -eq "$total2" ]
        then
            voting2=$(grep -f non-voting_address.txt voting_address.txt)
            if [ -z "$voting2" ]
            then
                echo "Extracted non-voting addresses are checked. Correct!"
            else
                echo -e "Check result is \e[1m\e[31mnot correct! \e[0mYou need to check it manually."
            fi
        fi
    fi
fi
notconnected=`timeout 8s tail -f ~/.0L/logs/node/current | grep "currently not connected"`
sleep 0.1
export TIME=`date +%Y-%m-%dT%H:%M:%S`
if [ -z "$notconnected" ]
then
    echo "$TIME [INFO] All addresses in active set are connected."
else
    echo "$TIME [WARN] Addresses of nodes that not connected."
    echo -e "\e[5;31m========\e[0m"
    echo "$notconnected" | grep -oP 'remote_peer.*\K[0-9A-F]{32}'
    echo -e "\e[5;31m========\e[0m"
fi