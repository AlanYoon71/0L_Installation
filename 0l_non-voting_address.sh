#!/bin/bash

echo ""
curl -i https://0lexplorer.io/validators > webpage_extract.txt
sleep 0.1
echo ""
grep -oE 'account_address":"([[:xdigit:]]{32})"' webpage_extract.txt | cut -d':' -f2 | tr -d '\"' > active_validator_set.txt
sleep 0.1
echo -e "Active validator addresses were extracted from https://0lexplorer.io/validators and saved as \e[1m\e[33mactive_validator_set.txt\e[0m."
echo -e "\e[1m\e[33m================================\e[0m"
cat active_validator_set.txt
echo -e "\e[1m\e[33m================================\e[0m"
export set1=`cat active_validator_set.txt | wc -l`
sleep 0.1
if [ -z "$set1" ]
then
    echo "The webpage is down now. Failed to extract active validator list."
else
    echo "Active validators total : $set1 nodes"
    echo ""
    echo "Script is searching the log for \"broadcast to all peers\" for 30 seconds."
    echo ""
fi
voting=`timeout 30s tail -f /home/node/.0L/logs/node/current | grep "broadcast to all peers"`
sleep 0.1
echo "$voting" > broadcast_log.txt
export TIME=`date +%Y-%m-%dT%H:%M:%S`
if [ -z "$voting" ]
then
    echo "$TIME [INFO] No broadcasting now."
    echo ""
else
    echo "$TIME [INFO] These addresses have pending vote and timeout status right now. If it doesn't last, no problem."
    echo -e "$TIME [INFO] If the consensus has already stopped, these addresses can be considered still \e[1m\e[32mactive\e[0m."
    echo -e "\e[1m\e[32m================================\e[0m"
    echo "$voting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq
    echo "$voting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq > voting_address.txt
    echo -e "\e[1m\e[32m================================\e[0m"
    total=`cat voting_address.txt | wc -l`
    sleep 0.1
    if [ -z "$total" ] ; then total=$set1 ; fi 
    votediff=`expr $set1 - $total`
    if [ -z "$set1" ]
    then
        :
    else
        export rate=`echo "scale=1; ($total * 100) / $set1" | bc`
        echo "Nodes with voting activity : $total nodes, Validator set : $set1 nodes"
        echo -e "Vote    Rate : $rate%, \e[1m\e[31m$votediff \e[0mnodes are not voting now."
        echo ""
    fi
    nonvoting=$(grep -vf voting_address.txt active_validator_set.txt)
    sleep 0.1
    export TIME=`date +%Y-%m-%dT%H:%M:%S`
    if [ -z "$nonvoting" ]
    then
        if [ -z "$set1" ]
        then
            :
        else
            echo "$TIME [INFO] All validators in the set are active and voting now. Great!"
        fi
    else
        echo "$TIME [INFO] These addresses are not in a pending vote and timeout state. It's normal while consensus is in progress."
        echo -e "$TIME [INFO] If the consensus has already stopped, these addresses can be considered \e[1m\e[31minactive\e[0m."
        echo -e "\e[1m\e[31m================================\e[0m"
        echo "$nonvoting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq
        echo "$nonvoting" | grep -oE '[[:xdigit:]]{32}' | cut -d ' ' -f1 | sort | uniq > non-voting_address.txt
        echo -e "\e[1m\e[31m================================\e[0m"
        export total2=`cat non-voting_address.txt | wc -l`
        if [ -z "$set1" ]
        then
            :
        else
            echo -e "No voting activity : \e[1m\e[31m$total2 \e[0mnodes, Validator set : $set1 nodes"
        fi
        if [ "$votediff" -eq "$total2" ]
        then
            voting2=$(grep -f non-voting_address.txt voting_address.txt)
            if [ -z "$voting2" ]
            then
                echo "Extracted non-voting addresses are checked. Correct!"
                echo ""
            else
                echo -e "Check result is \e[1m\e[31mnot correct! \e[0mYou need to check it manually."
                echo ""
            fi
        fi
    fi
fi