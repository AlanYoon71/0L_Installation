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

while true; do
    echo ""
    echo "Input mnemonic for your validator account "
    read -p "Mnemonic : " MNEMONIC
    echo ""
    break
done

webhook_url=""
send_discord_message() {
  local message=$1
  curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
}

message="\`\`\`fix\n Script started!\n\`\`\`"
send_discord_message "$message"
session="node"
tmux new-session -d -s $session &> /dev/null
window=0
tmux rename-window -t $session:$window 'node' &> /dev/null
PIDCHECK=$(pgrep libra)
sleep 0.5
if [[ -z $PIDCHECK ]]
then
  message="\`\`\` No running node process now. So this script will start node and check if you are in set.\`\`\`"
  send_discord_message "$message"
  tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
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
  if [[ -z $PROPDIFF ]]; then PROPDIFF=0; fi
  PID=$(pgrep libra)
  sleep 0.5
  if [[ -z $PID ]]; then PID=0; fi
  sleep 0.5
  if [[ -z "$PID" ]]
  then
    tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
    sleep 10
  fi
  SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  SET=`expr $INBOUND + $OUTBOUND +1`
  SETCHECK=`expr $INBOUND + $OUTBOUND`
  if [[ $LEDGER1 -eq $LEDGER2 ]] || [[ $HEIGHT1 -eq $HEIGHT2 ]]
  then
    message="\`\`\`diff\n- Your node can't sync and access network now. $JAIL  Script will restart node and check it again. -\n\`\`\`"
    send_discord_message "$message"
    PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
    sleep 5
    tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
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
      tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
      sleep 5
    else
      if [[ $HEIGHT1 -eq $HEIGHT2 ]]
      then
        message="\`\`\`diff\n- = = = = = Network stopped!! = = = = = -\n\`\`\`"
        send_discord_message "$message"
        if [[ $SYNC2 -eq $LEDGER2 ]]
        then
          message="\` Height : $HEIGHT2  Sync : $SYNC2  Fully synced.\`"
          send_discord_message "$message"
        else
          message="\` Height : $HEIGHT2  Sync : $SYNC2  Ledger : $LEDGER2  LAG : - $LAG\`"
          send_discord_message "$message"
        fi
      fi
    fi
  else
    if [[ $PROPDIFF -eq 0 ]]
    then
      if [[ -z "$SETCHECK" ]]
      then
        message="\`========== Fullnode ==========\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\` Height : +$HEIGHTDIFF > $HEIGHT2  Sync : +$SYNCDIFF > $SYNC2\`"
            send_discord_message "$message"
            message="\`\`\`diff\n- 0l Network is running, but your local node stopped syncing!! -\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
            sleep 5
            message="\` Node restarted!\`"
            send_discord_message "$message"
          else
            message="\` Height : +$HEIGHTDIFF > $HEIGHT2  Sync : +$SYNCDIFF > $SYNC2  Syncing now.\`"
            send_discord_message "$message"
          fi
        else
          message="\` Epoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\`"
          send_discord_message "$message"
          timer=0
          message="\` Total    balance : $BALANCET1 ---> $BALANCETDIFF > $BALANCET2\`"
          send_discord_message "$message"
          message="\` Unlocked balance : $BALANCEU1 ---> $BALANCEUDIFF > $BALANCEU2\`"
          send_discord_message "$message"
          if [[ $SETCHECK -eq 0 ]]
          then
            message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
            send_discord_message "$message"
          else
            PIDCHECK=$(pgrep libra)
            RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
            message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $RUNTIME\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`diff\n+ Epoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH  You entered the set successfully. Total $SET validators are active. +\n\`\`\`"
            send_discord_message "$message"
            timer=0
          fi
        fi
      else
        PIDCHECK=$(pgrep libra)
        RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
        message="\`+ ======= [ VALIDATOR ] ======== +  $RUNTIME\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`diff\n- Height : +$HEIGHTDIFF > $HEIGHT2  Sync : +$SYNCDIFF > $SYNC2  Prop : +$PROPDIFF > $PROP2  Alert! Syncing stopped. -\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
            sleep 5
            message="\` Node restarted!\`"
            send_discord_message "$message"
          else
            message="\`\`\`diff\n- Height : +$HEIGHTDIFF > $HEIGHT2  Sync : +$SYNCDIFF > $SYNC2  Prop : +$PROPDIFF > $PROP2  Syncing now, but not proposing. -\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
            sleep 5
            message="\` Node restarted!\`"
            send_discord_message "$message"
          fi
        else
          SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
          INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
          OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
          if [[ -z $INBOUND ]]; then INBOUND=0; fi
          if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
          SET=`expr $INBOUND + $OUTBOUND +1`
          SETCHECK=`expr $INBOUND + $OUTBOUND`
          message="\`\`\`arm\n Total    balance : $BALANCET1 ---> $BALANCETDIFF > $BALANCET2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\n Unlocked balance : $BALANCEU1 ---> $BALANCEUDIFF > $BALANCEU2\n\`\`\`"
          send_discord_message "$message"
          if [[ $SETCHECK -eq 0 ]]
          then
            message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\` Epoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\`\`\`"
            send_discord_message "$message"
            timer=0
            message="\`\`\` [[ You entered active validator set in new epoch again. ]]\nBut not proposing now. Validator needs to be restarted.\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 'ulimit -n 1048576 && RUST_LOG=info libra node' C-m
            sleep 5
            message="\` Node restarted!\`"
            send_discord_message "$message"
          fi
        fi
      fi
    else
      if [[ $EPOCHDIFF -gt 0 ]]
      then
        SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
        INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
        OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
        if [[ -z $INBOUND ]]; then INBOUND=0; fi
        if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
        SET=`expr $INBOUND + $OUTBOUND +1`
        SETCHECK=`expr $INBOUND + $OUTBOUND`
        PIDCHECK=$(pgrep libra)
        RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $RUNTIME\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\n Total    balance : $BALANCET1 ---> $BALANCET2  $BALANCETDIFF\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\n Unlocked balance : $BALANCEU1 ---> $BALANCEU2  $BALANCEUDIFF\n\`\`\`"
        send_discord_message "$message"
        if [[ $SETCHECK -eq 0 ]]
        then
          message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
          send_discord_message "$message"
        else
          message="\`\`\`diff\n+ Epoch jumped. $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH  You are in set. Total $SET validators are active. +\n\`\`\`"
          send_discord_message "$message"
          timer=0

        fi
      else
        if [[ $PROPDIFF -gt 0 ]]
        then
          PIDCHECK=$(pgrep libra)
          RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
          message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $RUNTIME\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\n Height : +$HEIGHTDIFF > $HEIGHT2  Sync : +$SYNCDIFF > $SYNC2  Prop : +$PROPDIFF > $PROP2  Proposing now.\`\`\`"
          send_discord_message "$message"
          if [[ $timer -gt 140 ]]
          then
            rm -f ./bid_list.txt &> /dev/null
            curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_all_validators_voting_power{peer_id= | awk -F'"' '{print $2}' > val_address.txt
            readarray -t addresses < val_address.txt
            for address in "${addresses[@]}"; do
                libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $address | jq -r '.bid' | tr -d '\"' >> bid_list.txt
                sleep 3
            done
            min_bid=$(cat bid_list.txt | awk '$1 > 0 {print}' bid_list.txt | sort -n | head -n 1)
            recommended_bidding_value=$(echo "scale=4; $min_bid / 1000 + 0.0001" | bc)
            message="\`\`\`arm\n Recommended biddng value : $recommended_bidding_value\n\`\`\`"
            send_discord_message "$message"
            bid1=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
            libra txs validator pof --bid-pct $recommended_pof_value --expiry 1000
            expect "mnemonic:"
            sleep 0.5
            send "$MNEMONIC\r"
            sleep 10
            bid2=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
            message="\`\`\`arm\n Bidding value updated! $bid1 ----> $bid2\n\`\`\`"
            send_discord_message "$message"
            timer=0
          fi
        fi
        if [[ $PROPDIFF -lt 0 ]]
        then
          SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
          INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
          OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -o "[0-9]*" | sort -r | head -1`
          if [[ -z $INBOUND ]]; then INBOUND=0; fi
          if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
          SET=`expr $INBOUND + $OUTBOUND +1`
          SETCHECK=`expr $INBOUND + $OUTBOUND`
          if [[ $SETCHECK -eq 0 ]]
          then
            message="\`\`\`diff\n- You failed to enter active validator set. $JAIL -\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`diff\n- Alert! Prop value was decreased for unknown reasons. Did you restart node? -\n\`\`\`"
            send_discord_message "$message"
          fi
        fi
        if [[ $PROPDIFF -eq 0 ]]
        then
          PIDCHECK=$(pgrep libra)
          RUNTIME=$(ps -p $PIDCHECK -o etime | awk 'NR==2')
          message="\`+ ======= [ VALIDATOR ] ======== +  $RUNTIME\`"
          send_discord_message "$message"
          message="\` Height : +$HEIGHTDIFF > $HEIGHT2  Sync : +$SYNCDIFF > $SYNC2  Prop : +$PROPDIFF > $PROP2  Proposing too slow...\`"
          send_discord_message "$message"
        fi
      fi
    fi
  fi
  start_flag=1
  timer=$((timer + 1))
done
