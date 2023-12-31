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

webhook_url=""
send_discord_message() {
  local message=$1
  curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
}
BALANCET1=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%'\''d %'\''d", $1, $2}' | cut -d ' ' -f 2)
sleep 1
BALANCEU1=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%'\''d %'\''d", $1, $2}' | cut -d ' ' -f 1)
sleep 1
TIME=`date +%Y-%m-%dT%H:%M:%S`
message="\`[$TIME] Script started!\`"
send_discord_message "$message"
message="\`[$TIME] Total    bal. : $BALANCET1\`"
send_discord_message "$message"
message="\`[$TIME] Unlocked bal. : $BALANCEU1\`"
send_discord_message "$message"
while true; do
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
  sleep 584
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
  sleep 0.2
  if [[ -z $HEIGHT2 ]]; then HEIGHT2=0; fi
  sleep 0.2
  if [[ -z $SYNC1 ]]; then SYNC1=0; fi
  sleep 0.2
  if [[ -z $SYNC2 ]]; then SYNC2=0; fi
  sleep 0.5
  if [[ -z $EPOCH1 ]]; then EPOCH1=0; fi
  sleep 0.2
  if [[ -z $EPOCH2 ]]; then EPOCH2=0; fi
  sleep 0.2
  if [[ -z $BALANCET1 ]]; then BALANCET1=0; fi
  sleep 0.5
  if [[ -z $BALANCET2 ]]; then BALANCET2=0; fi
  sleep 0.5
  if [[ -z $BALANCEU1 ]]; then BALANCEU1=0; fi
  sleep 0.5
  if [[ -z $BALANCEU2 ]]; then BALANCEU2=0; fi
  sleep 0.5
  if [[ -z $PROP1 ]]; then PROP1=0; fi
  sleep 0.2
  if [[ -z $PROP2 ]]; then PROP2=0; fi
  sleep 0.2
  if [[ -z $LEDGER1 ]]; then LEDGER1=0; fi
  sleep 0.2
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
  sleep 0.2
  if [[ $BALANCEUDIFF -gt 0 ]]; then BALANCEUDIFF="+$BALANCEUDIFF"; fi
  sleep 0.2
  if [[ -z $PROPDIFF ]]; then PROPDIFF=0; fi
  sleep 0.2
  PID=$(pgrep libra)
  sleep 0.5
  if [[ -z $PID ]]; then PID=0; fi
  sleep 0.5
  if [[ -z "$PID" ]]
  then
    tmux send-keys -t fullnode:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml' C-m
    sleep 10
  fi
  TIME=`date +%Y-%m-%dT%H:%M:%S`
  NODETYPE=`ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep"`
  if [[ $LEDGER1 -eq $LEDGER2 ]] || [[ $HEIGHT1 -eq $HEIGHT2 ]]
  then
    PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
    PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
    sleep 5
    tmux send-keys -t fullnode:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml' C-m
    sleep 10
  fi
  TIME=`date +%Y-%m-%dT%H:%M:%S`
  if [[ $LEDGER1 -eq $LEDGER2 ]] || [[ $HEIGHT1 -eq $HEIGHT2 ]]
  then
    message="\`[$TIME] = = = = = Network stopped!! = = = = =\`"
    send_discord_message "$message"
    if [[ $SYNC2 -eq $LEDGER2 ]]
    then
      message="\`[$TIME] Height : $HEIGHT2  Sync : $SYNC2  Vouch : $VOUCH  Fully synced.\`"
      send_discord_message "$message"
    else
      message="\`[$TIME] Height : $HEIGHT2  Sync : $SYNC2  Ledger : $LEDGER2  LAG : - $LAG\`"
      send_discord_message "$message"
    fi
  else
    if [[ $PROPDIFF -eq 0 ]]
    then
      if [[ -z "$NODETYPE" ]]
      then
        message="\`========== Fullnode ==========\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`[$TIME] Height : +$HEIGHTDIFF  Sync : +$SYNCDIFF  Sync stopped...\`"
            send_discord_message "$message"
            PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t fullnode:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml' C-m
            sleep 5
            TIME=`date +%Y-%m-%dT%H:%M:%S`
            message="\`[$TIME] Fullnode restarted!\`"
            send_discord_message "$message"
          else
            message="\`[$TIME] Height : +$HEIGHTDIFF  Sync : +$SYNCDIFF  Syncing now.\`"
            send_discord_message "$message"
          fi
        else
          message="\`[$TIME] Epoch jumped. $EPOCH1 ---> $EPOCH2\`"
          send_discord_message "$message"
          message="\`[$TIME] Total    bal. : $BALANCET1 ---> $BALANCET2  Diff. : $BALANCETDIFF\`"
          send_discord_message "$message"
          message="\`[$TIME] Unlocked bal. : $BALANCEU1 ---> $BALANCEU2  Diff. : $BALANCEUDIFF\`"
          send_discord_message "$message"
          PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
          PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
          sleep 5
          TIME=`date +%Y-%m-%dT%H:%M:%S`
          message="\`[$TIME] Checking if you are in set...\`"
          send_discord_message "$message"
          PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
          sleep 5
          tmux send-keys -t validator:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/validator.yaml' C-m
          sleep 120
          SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
          sleep 2
          TIME=`date +%Y-%m-%dT%H:%M:%S`
          if [[ -z $SETIN ]]
          then
            message="\`[$TIME] You failed to enter active validator set. $JAIL  Vouch : $VOUCH\`"
            send_discord_message "$message"
            PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t fullnode:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml' C-m
            sleep 5
          else
            message="\`[$TIME] [[ You are in active validator set now. ]]  Vouch : $VOUCH\nFullnode will be converted to validator.\`"
            send_discord_message "$message"
            message="\`[$TIME] Validator started!\`"
            send_discord_message "$message"
          fi
        fi
      else
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`[$TIME] Height : +$HEIGHTDIFF  Sync : +$SYNCDIFF  Prop : +$PROPDIFF  Alert! Sync stopped. Validator needs to be restarted.\`"
            send_discord_message "$message"
            PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t validator:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/validator.yaml' C-m
            sleep 5
            TIME=`date +%Y-%m-%dT%H:%M:%S`
            message="\`[$TIME] Validator restarted!\`"
            send_discord_message "$message"
          else
            message="\`[$TIME] Height : +$HEIGHTDIFF  Sync : +$SYNCDIFF  Syncing now, but not proposing. Validator needs to be restarted.\`"
            send_discord_message "$message"
            PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t validator:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/validator.yaml' C-m
            sleep 5
            TIME=`date +%Y-%m-%dT%H:%M:%S`
            message="\`[$TIME] Validator restarted!\`"
            send_discord_message "$message"
          fi
        else
          SETIN=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_validator_voting_power | grep -o '[0-9]*'`
          sleep 2
          message="\`\`\`[$TIME] Epoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
          send_discord_message "$message"
          message="\`\`\`[$TIME] Total    bal. : $BALANCET1 ---> $BALANCET2  Diff. : $BALANCETDIFF\`\`\`"
          send_discord_message "$message"
          message="\`\`\`[$TIME] Unlocked bal. : $BALANCEU1 ---> $BALANCEU2  Diff. : $BALANCEUDIFF\`\`\`"
          send_discord_message "$message"
          if [[ -z $SETIN ]]
          then
            message="\`[$TIME] You failed to enter active validator set. $JAIL  Vouch : $VOUCH\nValidator will be converted to fullnode for continuous syncing.\`"
            send_discord_message "$message"
            PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t fullnode:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/fullnode.yaml' C-m
            sleep 5
            TIME=`date +%Y-%m-%dT%H:%M:%S`
            message="\`[$TIME] Fullnode started!\`"
            send_discord_message "$message"
          else
            message="\`[$TIME] [[ You entered active validator set in new epoch again. ]]\nBut not proposing now. Validator needs to be restarted.\`"
            send_discord_message "$message"
            PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/validator.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(ps -ef | grep -e ".libra/fullnode.yaml" | grep -v "grep" | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t validator:0 'ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/validator.yaml' C-m
            sleep 5
            TIME=`date +%Y-%m-%dT%H:%M:%S`
            message="\`[$TIME] Validator restarted!\`"
            send_discord_message "$message"
          fi
        fi
      fi
    else
      if [[ $EPOCHDIFF -gt 0 ]]
      then
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`[$TIME] Epoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
        send_discord_message "$message"
        message="\`\`\`[$TIME] Total    bal. : $BALANCET1 ---> $BALANCET2  Diff. : $BALANCETDIFF\`\`\`"
        send_discord_message "$message"
        message="\`\`\`[$TIME] Unlocked bal. : $BALANCEU1 ---> $BALANCEU2  Diff. : $BALANCEUDIFF\`\`\`"
        send_discord_message "$message"
      else
        if [[ $PROPDIFF -gt 0 ]]
        then
          message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`[$TIME] Height : +$HEIGHTDIFF  Sync : +$SYNCDIFF  Prop : +$PROPDIFF  Proposing now.\`\`\`"
          send_discord_message "$message"
        fi
        if [[ $PROPDIFF -lt 0 ]]
        then
          message="\`+ ======= [ VALIDATOR ] ======== +\`"
          send_discord_message "$message"
          message="\`[$TIME] Prop value was changed for unknown reasons. Did you restart node?\`"
          send_discord_message "$message"
        fi
        if [[ $PROPDIFF -eq 0 ]]
        then
          message="\`+ ======= [ VALIDATOR ] ======== +\`"
          send_discord_message "$message"
          message="\`[$TIME] Height : +$HEIGHTDIFF  Sync : +$SYNCDIFF  Prop : +$PROPDIFF  Proposing too slow...\`"
          send_discord_message "$message"
        fi
      fi
    fi
  fi
done