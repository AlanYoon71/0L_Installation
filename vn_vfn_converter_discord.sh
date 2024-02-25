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

echo ""
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
    echo "You chosed to disable this function."
    echo ""
    echo "Script starts."
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
accountlaststring="${accountinput: -6}"
INSET1=`libra query resource --resource-path-string 0x1::stake::ValidatorSet --account 0x1 | jq -r '.active_validators[].addr' | grep -P $accountlaststring`
sleep 1
if [[ -z $INSET1 ]]
then
  INSET1=0
else
  INSET1=1
fi
session="node"
tmux new-session -d -s $session &> /dev/null
window=0
tmux rename-window -t $session:$window 'node' &> /dev/null
PIDCHECK=$(pgrep libra)
sleep 0.5
if [[ -z $PIDCHECK ]]
then
  if [[ $INSET1 -eq 0 ]]
  then
    message="\`\`\`No running node process now. And you are not in set.\`\`\`"
    send_discord_message "$message"
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
    message="\`\`\`VFN started.\`\`\`"
    send_discord_message "$message"
    sleep 60
  else
    message="\`\`\`No running node process now. And you are in set.\`\`\`"
    send_discord_message "$message"
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
    message="\`\`\`Validator started.\`\`\`"
    send_discord_message "$message"
    sleep 60
  fi
fi
restart_count=0
start_flag=0
SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
sleep 0.2
EPOCH1=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.epoch'`
sleep 0.2
LEDGER1=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
sleep 0.2
HEIGHT1=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.block_height' | grep -o -P '\d+'`
sleep 0.2
PROP1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_proposal\",result=\"success\" | grep -o '[0-9]*'`
sleep 0.2
EPOCHREWARD1=$(libra query resource --resource-path-string 0x1::proof_of_fee::ConsensusReward --account 0x1 | jq -r '.nominal_reward' | awk '{printf "%.2f\n", $1/1000000}')
sleep 0.2
NETREWARD1=$(libra query resource --resource-path-string 0x1::proof_of_fee::ConsensusReward --account 0x1 | jq -r '.net_reward' | awk '{printf "%.2f\n", $1/1000000}')
sleep 0.2
BALANCET1=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%.2f %.2f", $1, $2}' | cut -d ' ' -f 2)
sleep 0.2
TBALANCET1=$(echo "$BALANCET1" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
BALANCEU1=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%.2f %.2f", $1, $2}' | cut -d ' ' -f 1)
sleep 0.2
TBALANCEU1=$(echo "$BALANCEU1" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
if [[ -z $INBOUND ]]; then INBOUND=0; fi
if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
vfn_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
vfn_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
if [[ -z $vfn_in ]]; then vfn_in=0; fi
if [[ -z $vfn_out ]]; then vfn_out=0; fi
public_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Public | grep -oE '[0-9]+$'`
public_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Public | grep -oE '[0-9]+$'`
if [[ -z $public_in ]]; then public_in=0; fi
if [[ -z $public_out ]]; then public_out=0; fi
#SETCHECK1=`expr $INBOUND + $OUTBOUND`
#if [[ -z $SETCHECK1 ]]; then SETCHECK1=0; fi
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
    #SETCHECK1=$SETCHECK2
    INSET1=$INSET2
  fi
  accountlaststring="${accountinput: -6}"
  INSET2=`libra query resource --resource-path-string 0x1::stake::ValidatorSet --account 0x1 | jq -r '.active_validators[].addr' | grep -P $accountlaststring`
  sleep 1
  if [[ -z $INSET2 ]]
  then
    INSET2=0
  else
    INSET2=1
  fi
  PIDCHECK=$(pgrep libra)
  sleep 0.5
  if [[ -z $PIDCHECK ]]
  then
    if [[ $INSET2 -eq 0 ]]
    then
      message="\`\`\`No running node process now. And you are not in set.\`\`\`"
      send_discord_message "$message"
      tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
      message="\`\`\`VFN started.\`\`\`"
      send_discord_message "$message"
      sleep 60
    else
      message="\`\`\`No running node process now. And you are in set.\`\`\`"
      send_discord_message "$message"
      tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
      message="\`\`\`Validator started.\`\`\`"
      send_discord_message "$message"
      sleep 60
    fi
  fi
  sleep 600

  SYNC2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
  sleep 0.2
  EPOCH2=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.epoch'`
  sleep 0.2
  LEDGER2=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
  sleep 0.2
  HEIGHT2=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.block_height' | grep -o -P '\d+'`
  sleep 0.2
  PROP2=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_proposal\",result=\"success\" | grep -o '[0-9]*'`
  sleep 0.2
  JAIL=`libra query resource --resource-path-string 0x1::jail::Jail --account $accountinput | jq -r .is_jailed | grep -q "false" && echo "Not jailed." || echo "You are jailed."`
  sleep 0.2
  EPOCHREWARD2=$(libra query resource --resource-path-string 0x1::proof_of_fee::ConsensusReward --account 0x1 | jq -r '.nominal_reward' | awk '{printf "%.2f\n", $1/1000000}')
  sleep 0.2
  NETREWARD2=$(libra query resource --resource-path-string 0x1::proof_of_fee::ConsensusReward --account 0x1 | jq -r '.net_reward' | awk '{printf "%.2f\n", $1/1000000}')
  sleep 0.2
  BALANCET2=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%.2f %.2f", $1, $2}' | cut -d ' ' -f 2)
  sleep 0.2
  TBALANCET2=$(echo "$BALANCET2" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
  BALANCEU2=$(libra query balance --account $accountinput | jq -r '.unlocked, .total' | paste -sd " / " | awk '{printf "%.2f %.2f", $1, $2}' | cut -d ' ' -f 1)
  sleep 0.2
  TBALANCEU2=$(echo "$BALANCEU2" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
  VOUCH=`libra query resource --resource-path-string 0x1::vouch::MyVouches --account $accountinput | jq '.my_buddies | map(select(startswith("0x"))) | length'`
  sleep 0.2

  price_data=$(curl -s -X GET "https://api.0lswap.com/orders/getChartData?interval=1h&market=OLUSDT" | jq -r '.[-1]')
  high=$(echo "$price_data" | jq -r '.high')
  low=$(echo "$price_data" | jq -r '.low')
  #volume=$(echo "$price_data" | jq -r '.volume')
  high=$(printf "%.5f" $high)
  low=$(printf "%.5f" $low)
  #volume=$(printf "%.2f" $volume)
  average=$(echo "scale=5; ($high - $low) / 2 + $low" | bc)
  asset=$(echo "scale=2; $average * $BALANCET2" | bc)
  asset=$(printf "%.2f" "$asset")
  asset=$(echo "$asset" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
  ticker=$(echo "Price : \$$low ~ \$$high (OTC)  Asset value  : \$$asset")

  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  vfn_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  vfn_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  if [[ -z $vfn_in ]]; then vfn_in=0; fi
  if [[ -z $vfn_out ]]; then vfn_out=0; fi
  public_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Public | grep -oE '[0-9]+$'`
  public_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Public | grep -oE '[0-9]+$'`
  if [[ -z $public_in ]]; then public_in=0; fi
  if [[ -z $public_out ]]; then public_out=0; fi
  #SETCHECK2=`expr $INBOUND + $OUTBOUND`
  ACTIVE=`expr $INBOUND + $OUTBOUND + 1`
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
  #if [[ -z $SETCHECK2 ]]; then SETCHECK2=0; fi
  if [[ -z $EPOCHREWARD1 ]]; then EPOCHREWARD1=0; fi
  if [[ -z $EPOCHREWARD2 ]]; then EPOCHREWARD2=0; fi
  if [[ -z $NETREWARD1 ]]; then NETREWARD1=0; fi
  if [[ -z $NETREWARD2 ]]; then NETREWARD2=0; fi
  sleep 0.2
  LEDGERDIFF=`expr $LEDGER2 - $LEDGER1`
  LAG=`expr $LEDGER2 - $SYNC2`
  HEIGHTDIFF=`expr $HEIGHT2 - $HEIGHT1`
  EPOCHDIFF=`expr $EPOCH2 - $EPOCH1`
  SYNCDIFF=`expr $SYNC2 - $SYNC1`
  PROPDIFF=`expr $PROP2 - $PROP1`
  EPOCHREWARDDIFF=`echo "$EPOCHREWARD2 - $EPOCHREWARD1" | bc`
  NETREWARDDIFF=`echo "$NETREWARD2 - $NETREWARD1" | bc`
  BALANCETDIFF=`echo "$BALANCET2 - $BALANCET1" | bc`
  TBALANCETDIFF=$(echo "$BALANCETDIFF" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
  BALANCEUDIFF=`echo "$BALANCEU2 - $BALANCEU1" | bc`
  TBALANCEUDIFF=$(echo "$BALANCEUDIFF" | sed -E ':a;s/(.*[0-9])([0-9]{3})/\1,\2/;ta')
  if (( $(echo "$EPOCHREWARDDIFF >= 0" | bc -l) )); then EPOCHREWARDDIFF="+$EPOCHREWARDDIFF"; fi
  if (( $(echo "$NETREWARDDIFF >= 0" | bc -l) )); then NETREWARDDIFF="+$NETREWARDDIFF"; fi
  if (( $(echo "$BALANCETDIFF >= 0" | bc -l) )); then TBALANCETDIFF="+$TBALANCETDIFF"; fi
  if (( $(echo "$BALANCEUDIFF >= 0" | bc -l) )); then TBALANCEUDIFF="+$TBALANCEUDIFF"; fi
  if [ -e "vn_start_time.txt" ]; then
    start_time=$(< "vn_start_time.txt")
  fi
  if [[ $INSET2 -gt 0 ]] && [[ $INSET1 -eq 0 ]]
  then
    start_time=$(date +%s)
    echo "$start_time" > "vn_start_time.txt"
  fi
  if [[ -z $PROPDIFF ]]; then PROPDIFF=0; fi
  PID=$(pgrep libra)
  sleep 0.5
  if [[ -z $PID ]]; then PID=0; fi
  sleep 0.5
  if [[ -z "$PID" ]]
  then
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
    sleep 30
  fi
  if [[ $INSET2 -eq 0 ]]
  then
    PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
    sleep 5
    restart_count=1
    rm -f vn_start_time.txt
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
    sleep 30
  fi
  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  vfn_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  vfn_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  if [[ -z $vfn_in ]]; then vfn_in=0; fi
  if [[ -z $vfn_out ]]; then vfn_out=0; fi
  public_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Public | grep -oE '[0-9]+$'`
  public_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Public | grep -oE '[0-9]+$'`
  if [[ -z $public_in ]]; then public_in=0; fi
  if [[ -z $public_out ]]; then public_out=0; fi
  #SETCHECK2=`expr $INBOUND + $OUTBOUND`
  #if [[ -z $SETCHECK2 ]]; then SETCHECK2=0; fi
  ACTIVE=`expr $INBOUND + $OUTBOUND + 1`
  if [[ $LEDGER1 -ne $LEDGER2 ]] && [[ $SYNC1 -eq $SYNC2 ]]
  then
    if [[ $restart_count -eq 0 ]]
    then
      message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
      send_discord_message "$message"
      message="\`\`\`diff\n- 0l Network is running, but your local node stopped syncing!! -\n\`\`\`"
      send_discord_message "$message"
      PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
      sleep 5
      restart_count=1
      rm -f vn_start_time.txt
      if [[ $INSET -eq 0 ]]
      then
        tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
        sleep 20
      else
        tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
        sleep 20
      fi
      LEDGER2=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
      sleep 0.2
      HEIGHT2=`curl -s curl https://rpc.openlibra.space:8080/v1/ | jq -r '.block_height' | grep -o -P '\d+'`
      sleep 0.2
      if [[ -z $LEDGER2 ]]; then LEDGER2=0; fi
      if [[ -z $HEIGHT2 ]]; then HEIGHT2=0; fi
    fi
  fi
  if [[ $LEDGER1 -eq $LEDGER2 ]]
  then
    if [[ $HEIGHT1 -eq $HEIGHT2 ]]
    then
      message="\`\`\`= = = = = Open libra network stopped!! = = = = =\`\`\`"
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
  else
    if [[ $PROPDIFF -eq 0 ]]
    then
      if [[ $INSET2 -eq 0 ]]
      then
        message="\`\`\`arm\nVFN mode :  VFN network --> $vfn_out   $public_in --> [Public network] --> $public_out\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\n$ticker\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`diff\n- 0l Network is running, but your local node stopped syncing!! -\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            rm -f vn_start_time.txt
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nEpoch : $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nEpoch reward : Ƚ$EPOCHREWARD1 ---> Ƚ$EPOCHREWARD2 ( $EPOCHREWARDDIFF )\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nNet   reward : Ƚ$NETREWARD1 ---> Ƚ$NETREWARD2 ( $NETREWARDDIFF )\n\`\`\`"
          send_discord_message "$message"
          timer=0
          message="\`\`\`arm\nTotal    balance : Ƚ$TBALANCET1 ---> Ƚ$TBALANCET2 ( $TBALANCETDIFF )\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nUnlocked balance : Ƚ$TBALANCEU1 ---> Ƚ$TBALANCEU2 ( $TBALANCEUDIFF )\n\`\`\`"
          send_discord_message "$message"
          if [[ $INSET2 -eq 0 ]]
          then
            message="\`\`\`You are not in set. $JAIL\`\`\`"
            send_discord_message "$message"
            rm -f vn_start_time.txt
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
            sleep 5
          else
            message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $ACTIVE nodes in set are active now.$vn_runtime\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\n$ticker\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nEpoch : $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nEpoch reward : Ƚ$EPOCHREWARD1 ---> Ƚ$EPOCHREWARD2 ( $EPOCHREWARDDIFF )\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nNet   reward : Ƚ$NETREWARD1 ---> Ƚ$NETREWARD2 ( $NETREWARDDIFF )\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`diff\n+ You entered the set successfully. +\n\`\`\`"
            send_discord_message "$message"
          fi
        fi
      else
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $ACTIVE nodes in set are active now.$vn_runtime\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\n$ticker\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2  Alert! Syncing stopped.\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            rm -f vn_start_time.txt
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2  Syncing, but not proposing now.\n\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            rm -f vn_start_time.txt
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node" C-m
            sleep 5
            message="\`\`\`fix\nNode restarted!\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          timer=0
          INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
          OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
          if [[ -z $INBOUND ]]; then INBOUND=0; fi
          if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
          vfn_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
          vfn_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
          if [[ -z $vfn_in ]]; then vfn_in=0; fi
          if [[ -z $vfn_out ]]; then vfn_out=0; fi
          public_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Public | grep -oE '[0-9]+$'`
          public_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Public | grep -oE '[0-9]+$'`
          if [[ -z $public_in ]]; then public_in=0; fi
          if [[ -z $public_out ]]; then public_out=0; fi
          #SETCHECK2=`expr $INBOUND + $OUTBOUND`
          ACTIVE=`expr $INBOUND + $OUTBOUND + 1`
          message="\`\`\`arm\nTotal    balance : Ƚ$TBALANCET1 ---> Ƚ$TBALANCET2 ( $TBALANCETDIFF )\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nUnlocked balance : Ƚ$TBALANCEU1 ---> Ƚ$TBALANCEU2 ( $TBALANCEUDIFF )\n\`\`\`"
          send_discord_message "$message"
          if [[ $INSET2 -eq 0 ]]
          then
            message="\`\`\`You are not in set. $JAIL\`\`\`"
            send_discord_message "$message"
            rm -f vn_start_time.txt
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
            sleep 5
          else
            message="\`\`\`arm\nEpoch : $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nEpoch reward : Ƚ$EPOCHREWARD1 ---> Ƚ$EPOCHREWARD2 ( $EPOCHREWARDDIFF )\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nNet   reward : Ƚ$NETREWARD1 ---> Ƚ$NETREWARD2 ( $NETREWARDDIFF )\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`You entered active validator set in new epoch again. But not proposing now. Validator needs to be restarted.\`\`\`"
            send_discord_message "$message"
            PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
            sleep 5
            rm -f vn_start_time.txt
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
        INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
        OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
        if [[ -z $INBOUND ]]; then INBOUND=0; fi
        if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
        vfn_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
        vfn_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
        if [[ -z $vfn_in ]]; then vfn_in=0; fi
        if [[ -z $vfn_out ]]; then vfn_out=0; fi
        public_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Public | grep -oE '[0-9]+$'`
        public_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Public | grep -oE '[0-9]+$'`
        if [[ -z $public_in ]]; then public_in=0; fi
        if [[ -z $public_out ]]; then public_out=0; fi
        #SETCHECK2=`expr $INBOUND + $OUTBOUND`
        ACTIVE=`expr $INBOUND + $OUTBOUND + 1`
        message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $ACTIVE nodes in set are active now.$vn_runtime\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\n$ticker\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\nProposal : +$PROPDIFF > $PROP2  Synced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\nTotal    balance : Ƚ$TBALANCET1 ---> Ƚ$TBALANCET2 ( $TBALANCETDIFF )\n\`\`\`"
        send_discord_message "$message"
        message="\`\`\`arm\nUnlocked balance : Ƚ$TBALANCEU1 ---> Ƚ$TBALANCEU2 ( $TBALANCEUDIFF )\n\`\`\`"
        send_discord_message "$message"
        if [[ $INSET2 -eq 0 ]]
        then
          message="\`\`\`You are not in set. $JAIL\`\`\`"
          send_discord_message "$message"
          rm -f vn_start_time.txt
          PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
          sleep 5
          tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
          sleep 5
        else
          message="\`\`\`arm\nEpoch : $EPOCH1 ---> $EPOCH2  Vouches : $VOUCH\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nEpoch reward : Ƚ$EPOCHREWARD1 ---> Ƚ$EPOCHREWARD2 ( $EPOCHREWARDDIFF )\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nNet   reward : Ƚ$NETREWARD1 ---> Ƚ$NETREWARD2 ( $NETREWARDDIFF )\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`diff\n+ You entered the set successfully. +\n\`\`\`"
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
            vn_runtime=" Set entry hold time : ${days}d ${hours}h ${minutes}m"
          fi
          message="\`\`\`diff\n+ ======= [ VALIDATOR ] ======== +  $ACTIVE nodes in set are active now.$vn_runtime\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\n$ticker\n\`\`\`"
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
            echo "$start_time" > "vn_start_time.txt"
            INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
            OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Validator | grep -oE '[0-9]+$'`
            if [[ -z $INBOUND ]]; then INBOUND=0; fi
            if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
            vfn_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
            vfn_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
            if [[ -z $vfn_in ]]; then vfn_in=0; fi
            if [[ -z $vfn_out ]]; then vfn_out=0; fi
            public_in=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"Public | grep -oE '[0-9]+$'`
            public_out=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"Public | grep -oE '[0-9]+$'`
            if [[ -z $public_in ]]; then public_in=0; fi
            if [[ -z $public_out ]]; then public_out=0; fi
            #SETCHECK2=`expr $INBOUND + $OUTBOUND`
            if [[ $INSET2 -eq 0 ]]
            then
              message="\`\`\`You are not in set. $JAIL\`\`\`"
              send_discord_message "$message"
              rm -f vn_start_time.txt
              PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
              sleep 5
              tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
              sleep 5
            fi
          else
            if [[ $PROPDIFF -eq 0 ]]
            then
              message="\`\`\`+ ======= [ VALIDATOR ] ======== +  $ACTIVE nodes in set are active now.$vn_runtime\n\`\`\`"
              send_discord_message "$message"
              message="\`\`\`arm\n$ticker\n\`\`\`"
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
