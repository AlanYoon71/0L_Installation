#!/bin/bash

while true; do
    echo ""
    echo "Input your validator 64-digit account address.(exclude 0x)"
    read -p "account : " accountinput
    echo ""
    if [[ $accountinput =~ ^[A-Z0-9]{1,31}$ ]]; then
        echo "Input 64-digit full account address exactly, please."
    else
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        echo "Your account is $accountinput. Accepted."
        break
    fi
done

echo "Do you want to adjust your bidding value to average level in set? (y/n)"
echo "After two epochs, this function will be activated once every time epoch is changed."
read -p "y/n : " user_input
if [[ $user_input == "y" ]]; then
    echo "You chosed to proceed. This function needs your mnemonic."
    echo ""
    echo "Input mnemonic for your validator account "
    read -p "Mnemonic : " MNEMONIC
    echo ""
    echo "Script starts."
elif [[ $user_input == "n" ]]; then
    echo "You chosed to disable this function. Script starts."
else
    echo "Invalid input. Please enter 'y' or 'n'."
    exit
fi

webhook_url=""
send_discord_message() {
  local message=$1
  curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
}

message="\`\`\`Script started!\`\`\`"
send_discord_message "$message"
session="node"
tmux new-session -d -s $session &> /dev/null
window=0
tmux rename-window -t $session:$window 'node' &> /dev/null
PIDCHECK=$(pgrep libra)
sleep 0.5
if [[ -z $PIDCHECK ]]
then
  message="\`\`\`No running node process now. So this script will start node and check if you are in set.\`\`\`"
  send_discord_message "$message"
  tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
  sleep 60
fi
start_flag=0
SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
sleep 0.2
EPOCH1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_storage_next_block_epoch | grep -o '[0-9]*'`
sleep 0.5
LEDGER1=`curl -s localhost:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
sleep 0.2
HEIGHT1=`curl -s localhost:8080/v1/ | jq -r '.block_height'`
sleep 0.2
PROP1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_proposal\",result=\"success\" | grep -o '[0-9]*'`
sleep 0.2
BALANCET1=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%'\''d %'\''d", $1, $2}' | cut -d ' ' -f 2)
sleep 1
BALANCEU1=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%'\''d %'\''d", $1, $2}' | cut -d ' ' -f 1)
sleep 1
INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
if [[ -z $INBOUND ]]; then INBOUND=0; fi
if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
SETCHECK1=`expr $INBOUND + $OUTBOUND`
while true; do
  if [[ $start_flag -eq 1 ]]
  then
    SYNC1=$SYNC2
    EPOCH1=$EPOCH2
    LEDGER1=$LEDGER2
    HEIGHT1=$HEIGHT2
    PROP1=$PROP2
    BALANCET1=$BALANCET2
    BALANCEU1=$BALANCEU2
    SETCHECK1=$SETCHECK2
  fi
  sleep 600
  SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
  sleep 0.2
  EPOCH2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_storage_next_block_epoch | grep -o '[0-9]*'`
  sleep 0.5
  LEDGER2=`curl -s localhost:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
  sleep 0.2
  HEIGHT2=`curl -s localhost:8080/v1/ | jq -r '.block_height'`
  sleep 0.2
  PROP2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_proposal\",result=\"success\" | grep -o '[0-9]*'`
  sleep 0.2
  JAIL=`libra query resource --resource-path-string 0x1::jail::Jail --account $accountinput | jq -r .is_jailed | grep -q "false" && echo "Not jailed." || echo "You are jailed."`
  sleep 0.2
  BALANCET2=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%'\''d %'\''d", $1, $2}' | cut -d ' ' -f 2)
  sleep 1
  BALANCEU2=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%'\''d %'\''d", $1, $2}' | cut -d ' ' -f 1)
  sleep 1
  VOUCH=`libra query resource --resource-path-string 0x1::vouch::MyVouches --account $accountinput | jq '.my_buddies | map(select(startswith("0x"))) | length'`
  sleep 1
  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  SETCHECK2=`expr $INBOUND + $OUTBOUND`
  SET=`expr $SETCHECK2 + 1`
  if [[ -z $HEIGHT1 ]]; then HEIGHT1=0; fi
  if [[ -z $HEIGHT2 ]]; then HEIGHT2=0; fi
  if [[ -z $SYNC1 ]]; then SYNC1=0; fi
  if [[ -z $SYNC2 ]]; then SYNC2=0; fi
  if [[ -z $EPOCH1 ]]; then EPOCH1=0; fi
  if [[ -z $EPOCH2 ]]; then EPOCH2=0; fi
  if [[ -z $BALANCET1 ]]; then BALANCET1=0; fi
  if [[ -z $BALANCET2 ]]; then BALANCET2=0; fi
  if [[ -z $BALANCEU1 ]]; then BALANCEU1=0; fi
  if [[ -z $BALANCEU2 ]]; then BALANCEU2=0; fi
  if [[ -z $PROP1 ]]; then PROP1=0; fi
  if [[ -z $PROP2 ]]; then PROP2=0; fi
  if [[ -z $LEDGER1 ]]; then LEDGER1=0; fi
  if [[ -z $LEDGER2 ]]; then LEDGER2=0; fi
  sleep 0.2
  LEDGERDIFF=`expr $LEDGER2 - $LEDGER1`
  LAG=`expr $LEDGER2 - $SYNC2`
  HEIGHTDIFF=`expr $HEIGHT2 - $HEIGHT1`
  EPOCHDIFF=`expr $EPOCH2 - $EPOCH1`
  SYNCDIFF=`expr $SYNC2 - $SYNC1`
  PROPDIFF=`expr $PROP2 - $PROP1`
  BALANCETDIFF=`expr $BALANCET2 - $BALANCET1`
  sleep 0.2
  BALANCEUDIFF=`expr $BALANCEU2 - $BALANCEU1`
  sleep 0.2
  if [[ $BALANCETDIFF -gt 0 ]]; then BALANCETDIFF="+$BALANCETDIFF"; fi
  if [[ $BALANCEUDIFF -gt 0 ]]; then BALANCEUDIFF="+$BALANCEUDIFF"; fi
  if [[ $SETCHECK2 -gt 0 ]] && [[ $SETCHECK1 -eq 0 ]]
  then
    start_time=$(date +%s)
  fi
  if [[ -z $PROPDIFF ]]; then PROPDIFF=0; fi
  PID=$(pgrep libra)
  sleep 0.5
  if [[ -z $PID ]]; then PID=0; fi
  sleep 0.5
  if [[ -z "$PID" ]]
  then
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
    sleep 10
  fi
  SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  SETCHECK2=`expr $INBOUND + $OUTBOUND`
  SET=`expr $INBOUND + $OUTBOUND + 1`
  if [[ $LEDGER1 -eq $LEDGER2 ]] || [[ $HEIGHT1 -eq $HEIGHT2 ]]
  then
    message="\`\`\`diff\n- Your node can't sync and access network now. $JAIL  Script will restart node and check it again. -\n\`\`\`"
    send_discord_message "$message"
    PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
    sleep 5
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
    sleep 10
  fi
  if [[ $LEDGER1 -eq $LEDGER2 ]]
  then
    if [[ $SETCHECK -eq 0 ]]
    then
      message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
      send_discord_message "$message"
      PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
      sleep 5
      tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
      sleep 5
    else
      if [[ $HEIGHT1 -eq $HEIGHT2 ]]
      then
        message="\`\`\`= = = = = Network stopped!! = = = = =\`\`\`"
        send_discord_message "$message"
        if [[ $SYNC2 -eq $LEDGER2 ]]
        then
          message="\`\`\`arm\nHeight : $HEIGHT2  Sync : $SYNC2  Fully synced.\n\`\`\`"
          send_discord_message "$message"
        else
          message="\`\`\`arm\nHeight : $HEIGHT2  Sync : $SYNC2  Ledger : $LEDGER2  LAG : - $LAG\n\`\`\`"
          send_discord_message "$message"
        fi
      fi
    fi
  else
    if [[ $PROPDIFF -eq 0 ]]
    then
      if [[ -z "$SETCHECK" ]]
      then
        message="\`\`\`fix\n+ ------ Fullnode ------ +\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2. Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`diff\n- 0l Network is running, but your local node stopped syncing!! -\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2. Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
          send_discord_message "$message"
          timer=0
          message="\`\`\`arm\nTotal    balance : $BALANCET1 ---> $BALANCETDIFF > $BALANCET2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nUnlocked balance : $BALANCEU1 ---> $BALANCEUDIFF > $BALANCEU2\n\`\`\`"
          send_discord_message "$message"
          if [[ $SETCHECK -eq 0 ]]
          then
            message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
            send_discord_message "$message"
          else
            PIDCHECK=$(pgrep libra)
            RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
            message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +   $SET validators in set.$vn_runtime\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\n$SETCHECK validators are connected. You entered the set successfully.\n\`\`\`"
            send_discord_message "$message"
          fi
        fi
      else
        PIDCHECK=$(pgrep libra)
        RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +   $SET validators in set.$vn_runtime\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2  Alert! Syncing stopped.\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2  Syncing, but not proposing now.\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          timer=0
          SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
          INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
          OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
          if [[ -z $INBOUND ]]; then INBOUND=0; fi
          if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
          SETCHECK2=`expr $INBOUND + $OUTBOUND`
          SET=`expr $INBOUND + $OUTBOUND + 1`
          message="\`\`\`arm\nTotal    balance : $BALANCET1 ---> $BALANCETDIFF > $BALANCET2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nUnlocked balance : $BALANCEU1 ---> $BALANCEUDIFF > $BALANCEU2\n\`\`\`"
          send_discord_message "$message"
          if [[ $SETCHECK -eq 0 ]]
          then
            message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`You entered active validator set in new epoch again. But not proposing now. Validator needs to be restarted.\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          fi
        fi
      fi
    else
      if [[ $EPOCHDIFF -gt 0 ]]
      then
        timer=0
        SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
        INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
        OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
        if [[ -z $INBOUND ]]; then INBOUND=0; fi
        if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
        SETCHECK2=`expr $INBOUND + $OUTBOUND`
        SET=`expr $INBOUND + $OUTBOUND + 1`
        PIDCHECK=$(pgrep libra)
        RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +   $SET validators in set.$vn_runtime\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\nTotal    balance : $BALANCET1 ---> $BALANCET2  $BALANCETDIFF\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\nUnlocked balance : $BALANCEU1 ---> $BALANCEU2  $BALANCEUDIFF\n\`\`\`"
        send_discord_message "$message"
        if [[ $SETCHECK -eq 0 ]]
        then
          message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
          send_discord_message "$message"
        else
          message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\n$SETCHECK2 validators are connected. You entered the set successfully.\n\`\`\`"
          send_discord_message "$message"
        fi
      else
        if [[ $PROPDIFF -gt 0 ]]
        then
          PIDCHECK=$(pgrep libra)
          if [[ -z $start_time ]]
          then
            :
          else
            current_time=$(date +%s)
            time_difference=$((current_time - start_time))
            days=$((time_difference / 86400))
            hours=$(( (time_difference % 86400) / 3600 ))
            minutes=$(( (time_difference % 3600) / 60 ))
            days=$(printf "%02d" $days)
            hours=$(printf "%02d" $hours)
            minutes=$(printf "%02d" $minutes)
            vn_runtime="  VN uptime : ${days}d ${hours}h ${minutes}m"
          fi
          message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +   $SET validators in set.$vn_runtime\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
          send_discord_message "$message"
          if [[ $timer -eq 132 ]]
          then
            rm -f ./bid_list.txt &> /dev/null
            curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_all_validators_voting_power{peer_id= | awk -F'"' '{print $2}' > val_address.txt
            readarray -t addresses < val_address.txt
            for address in "${addresses[@]}"; do
                libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $address | jq -r '.bid' | tr -d '\"' >> bid_list.txt
                sleep 3
            done
            average_bid=$(awk '{if($1!=0) {sum+=$1; count++}} END{if(count>0) printf "%.0f\n", sum/count; else print "No non-zero numbers found."}' bid_list.txt)
            bid1=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
            if [[ $bid1 -eq $average_bid ]]
            then
              :
            else
              recommended_bidding_value=$(echo "scale=3; $average_bid / 1000" | bc)
              message="\`\`\`arm\nRecommended biddng value : $recommended_bidding_value\n\`\`\`"
              send_discord_message "$message"
              expect <<EOF
              spawn libra txs validator pof --bid-pct $recommended_bidding_value --expiry 1000
              expect "🔑"
              send "$MNEMONIC\r"
              expect eof
EOF
              sleep 5
              bid2=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
              bid1=$(awk "BEGIN { printf \"%.1f\", $bid1 / 10 }") && bid1="$bid1%"
              bid2=$(awk "BEGIN { printf \"%.1f\", $bid2 / 10 }") && bid2="$bid2%"
              message="\`\`\`arm\nEntry fee updated! $bid1 ----> $bid2\n\`\`\`"
              send_discord_message "$message"
            fi
          fi
        else
          if [[ $PROPDIFF -lt 0 ]] && [[ $PROP2 -ne 0 ]]
          then
            start_time=$(date +%s)
            SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
            INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
            OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
            if [[ -z $INBOUND ]]; then INBOUND=0; fi
            if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
            SETCHECK=`expr $INBOUND + $OUTBOUND`
            SET=`expr $INBOUND + $OUTBOUND + 1`
            if [[ $SETCHECK -eq 0 ]]
            then
              message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
              send_discord_message "$message"
            fi
          else
            if [[ $PROPDIFF -eq 0 ]]
            then
              PIDCHECK=$(pgrep libra)
              RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
              message="\`\`\`+ ======= [ VALIDATOR ] ======== +  $RUNTIME elapsed\n\`\`\`"
              send_discord_message "$message"
              message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2  Proposing too slow.\n\`\`\`"
              send_discord_message "$message"
            fi
          fi
        fi
      fi
    fi
  fi
  start_flag=1
  timer=$((timer + 1))
done
