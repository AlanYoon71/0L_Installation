#!/bin/bash

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
  message="\`\`\`No running node process now. So this script will start node and verifies its sync status.\`\`\`"
  send_discord_message "$message"
  tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
  sleep 60
fi
restart_count=0
start_flag=0
SYNC1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
sleep 0.2
EPOCH1=`curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_storage_next_block_epoch | grep -o '[0-9]*'`
sleep 0.5
LEDGER1=`curl -s localhost:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
sleep 0.2
HEIGHT1=`curl -s localhost:8080/v1/ | jq -r '.block_height'`
sleep 0.2
INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
if [[ -z $INBOUND ]]; then INBOUND=0; fi
if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
SETCHECK1=`expr $INBOUND + $OUTBOUND`
if [[ -z $SETCHECK1 ]]; then SETCHECK1=0; fi
while true; do
  if [[ $start_flag -eq 1 ]]
  then
    SYNC1=$SYNC2
    EPOCH1=$EPOCH2
    LEDGER1=$LEDGER2
    HEIGHT1=$HEIGHT2
    SETCHECK1=$SETCHECK2
  fi
  PIDCHECK=$(pgrep libra)
  sleep 0.5
  if [[ -z $PIDCHECK ]]
  then
    session="node"
    tmux new-session -d -s $session &> /dev/null
    window=0
    tmux rename-window -t $session:$window 'node' &> /dev/null
    message="\`\`\`No running node process now. So this script will start node and verifies its sync status.\`\`\`"
    send_discord_message "$message"
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
    sleep 60
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
  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  SETCHECK2=`expr $INBOUND + $OUTBOUND`
  if [[ -z $SETCHECK2 ]]; then SETCHECK2=0; fi
  if [[ -z $HEIGHT1 ]]; then HEIGHT1=0; fi
  if [[ -z $HEIGHT2 ]]; then HEIGHT2=0; fi
  if [[ -z $SYNC1 ]]; then SYNC1=0; fi
  if [[ -z $SYNC2 ]]; then SYNC2=0; fi
  if [[ -z $EPOCH1 ]]; then EPOCH1=0; fi
  if [[ -z $EPOCH2 ]]; then EPOCH2=0; fi
  if [[ -z $LEDGER1 ]]; then LEDGER1=0; fi
  if [[ -z $LEDGER2 ]]; then LEDGER2=0; fi
  sleep 0.2
  LEDGERDIFF=`expr $LEDGER2 - $LEDGER1`
  LAG=`expr $LEDGER2 - $SYNC2`
  HEIGHTDIFF=`expr $HEIGHT2 - $HEIGHT1`
  EPOCHDIFF=`expr $EPOCH2 - $EPOCH1`
  SYNCDIFF=`expr $SYNC2 - $SYNC1`
  if [ -e "vfn_start_time.txt" ]; then
    start_time=$(< "vfn_start_time.txt")
  fi
  if [[ $SETCHECK2 -gt 0 ]] && [[ $SETCHECK1 -eq 0 ]]
  then
    start_time=$(date +%s)
    echo "$start_time" > "vfn_start_time.txt"
  fi
  if [[ -z $PROPDIFF ]]; then PROPDIFF=0; fi
  PID=$(pgrep libra)
  sleep 0.5
  if [[ -z $PID ]]; then PID=0; fi
  sleep 0.5
  if [[ -z "$PID" ]]
  then
    tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
    sleep 10
    if [[ $SETCHECK2 -eq 0 ]]
    then
      PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
      sleep 5
      restart_count=1
      rm -f vfn_start_time.txt
      tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
      sleep 10
    fi
  fi
  INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
  if [[ -z $INBOUND ]]; then INBOUND=0; fi
  if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
  SETCHECK2=`expr $INBOUND + $OUTBOUND`
  if [[ $LEDGER1 -eq $LEDGER2 ]] || [[ $HEIGHT1 -eq $HEIGHT2 ]]
  then
    if [[ $restart_count -eq 0 ]]
    then
      message="\`\`\`diff\n- Your node can't sync and access network now. $JAIL Script will restart node and check it again. -\n\`\`\`"
      send_discord_message "$message"
      PID=$(pgrep libra) && kill -TERM $PID &> /dev/null && sleep 1 && PID=$(pgrep libra) && kill -TERM $PID &> /dev/null
      sleep 5
      restart_count=1
      rm -f vfn_start_time.txt
      tmux send-keys -t node:0 "ulimit -n 1048576 && RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
      sleep 10
      LEDGER2=`curl -s localhost:8080/v1/ | jq -r '.ledger_version' | grep -o -P '\d+'`
      sleep 0.2
      HEIGHT2=`curl -s localhost:8080/v1/ | jq -r '.block_height'`
      sleep 0.2
      if [[ -z $LEDGER2 ]]; then LEDGER2=0; fi
      if [[ -z $HEIGHT2 ]]; then HEIGHT2=0; fi
    fi
  fi
  if [[ $LEDGER1 -eq $LEDGER2 ]]
  then
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
  else
    if [[ $SYNCDIFF -eq 0 ]]
    then
      if [[ $SETCHECK2 -eq 0 ]]
      then
        message="\`\`\`fix\n+ ------ Fullnode ------ +\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`diff\n- 0l Network is running, but node stopped syncing!! Check your seeds. -\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
          send_discord_message "$message"
          timer=0
          if [[ $SETCHECK2 -eq 0 ]]
          then
            message="\`\`\`Lost connection with Validator.\`\`\`"
            send_discord_message "$message"
            rm -f vfn_start_time.txt
          else
            PIDCHECK=$(pgrep libra)
            message="\`\`\`diff\n+ ======= [ Validator FullNode ] ======== +  Connected to Validator.$vn_runtime\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
            send_discord_message "$message"
            message="\`\`\`diff\n+ Connected to Validator successfully. +\n\`\`\`"
            send_discord_message "$message"
          fi
        fi
      else
        PIDCHECK=$(pgrep libra)
        message="\`\`\`diff\n+ ======= [ Validator FullNode ] ======== +  Connected to Validator.$vn_runtime\n\`\`\`"
        send_discord_message "$message"
        if [[ $EPOCH1 -eq $EPOCH2 ]]
        then
          if [[ $SYNC1 -eq $SYNC2 ]]
          then
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2  Alert! Syncing stopped.\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          timer=0
          INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
          OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
          if [[ -z $INBOUND ]]; then INBOUND=0; fi
          if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
          SETCHECK2=`expr $INBOUND + $OUTBOUND`
          if [[ $SETCHECK2 -eq 0 ]]
          then
            message="\`\`\`Lost connection with Validator.\`\`\`"
            send_discord_message "$message"
            rm -f vfn_start_time.txt
          else
            message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
            send_discord_message "$message"
            message="\`\`\`You are connected to Validator in new epoch again. But not syncing now. Check your validator status.\`\`\`"
            send_discord_message "$message"
          fi
        fi
      fi
    else
      if [[ $EPOCHDIFF -gt 0 ]]
      then
        timer=0
        INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
        OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
        if [[ -z $INBOUND ]]; then INBOUND=0; fi
        if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
        SETCHECK2=`expr $INBOUND + $OUTBOUND`
        PIDCHECK=$(pgrep libra)
        if [[ $SETCHECK2 -eq 0 ]]
        then
          message="\`\`\`fix\n+ ------ Fullnode ------ +\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
          send_discord_message "$message"
          message="\`\`\`Lost connection with Validator.\`\`\`"
          send_discord_message "$message"
          rm -f vfn_start_time.txt
        else
          message="\`\`\`diff\n+ ======= [ Validator FullNode ] ======== +  Connected to Validator.$vn_runtime\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
          send_discord_message "$message"
          message="\`\`\`arm\nEpoch jumped. $EPOCH1 ---> $EPOCH2\`\`\`"
          send_discord_message "$message"
          message="\`\`\`diff\n+ Connected to Validator successfully. +\n\`\`\`"
          send_discord_message "$message"
        fi
      else
        if [[ $SYNCDIFF -gt 0 ]]
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
            vn_runtime=" Connected Time : ${days}d ${hours}h ${minutes}m"
          fi
          if [[ $SETCHECK2 -eq 0 ]]
          then
            message="\`\`\`fix\n+ ------ Fullnode ------ +\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
          else
            message="\`\`\`diff\n+ ======= [ Validator FullNode ] ======== +  Connected to Validator.$vn_runtime\n\`\`\`"
            send_discord_message "$message"
            message="\`\`\`arm\nSynced version : +$SYNCDIFF > $SYNC2  Block height : +$HEIGHTDIFF > $HEIGHT2\n\`\`\`"
            send_discord_message "$message"
          fi
        else
          if [[ $SYNCDIFF -lt 0 ]] && [[ $SYNC2 -ne 0 ]]
          then
            start_time=$(date +%s)
            echo "$start_time" > "vfn_start_time.txt"
            INBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"inbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
            OUTBOUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections{direction=\"outbound\",network_id=\"vfn | grep -oE '[0-9]+$'`
            if [[ -z $INBOUND ]]; then INBOUND=0; fi
            if [[ -z $OUTBOUND ]]; then OUTBOUND=0; fi
            SETCHECK2=`expr $INBOUND + $OUTBOUND`
            if [[ $SETCHECK2 -eq 0 ]]
            then
              message="\`\`\`Lost connection with Validator.\`\`\`"
              send_discord_message "$message"
              rm -f vfn_start_time.txt
            fi
          fi
        fi
      fi
    fi
  fi
  start_flag=1
  timer=$((timer + 1))
done
