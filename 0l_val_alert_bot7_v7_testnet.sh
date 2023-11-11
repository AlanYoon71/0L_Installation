#!/bin/bash

if [ -x /usr/bin/bc ]; then
    :
else
    echo "Installing bc package for calculating data.."
    sudo apt-get update
    sudo apt-get install -y bc
fi
if [ -x /usr/bin/mpstat ]; then
    :
else
    echo "Installing sysstat package for monitoring resource.."
    sudo apt-get update
    sudo apt-get install sysstat
fi
PATH=$PATH:/home/node/bin
webhook_url=""

while true; do
    echo ""
    echo "Input your validator account address.(exclude 0x)"
    read -p "account : " accountinput
    echo ""
    if [[ $accountinput =~ ^[A-Z0-9]{1,31}$ ]]; then
        echo "Input full account address exactly, please."
    else
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        echo "Your account is $accountinput. Accepted."
        break
    fi
done

# Initialize previous values
prev_epoch=0
prev_round=0
prev_sync=0
prev_vote=0
prev_vote_reset=0
last_vote=0
prev_proposal=0
prev_proof=0
refresh3=0
setcheck=0
# Initialize counters
unchanged_counter=0
changed_counter=0
scriptstart=0
firstepoch=0
break_counter=0
RESTORECHECK=0
FAST=""
FAST2=""
restartcount=0
restorecount=0
# Initialize flags
message_printed=0
consensus_restart=0
restart_message_printed=0
restart_flag=0
delay=0

curl_output=$(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections | grep network_id=\"Validator\")
if [[ -z $curl_output ]]; then
  fullnode=1
else
  fullnode=0
fi
ADDRESSLIST=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep 'diem_all_validators_voting_power{peer_id=' | awk -F'"' '{print $2}' | tr ' ' '\n' | wc -l`
#ACCOUNT=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections\{direction=\"inbound\",network_id=\"Validator\",peer_id= | grep -oE '([[:xdigit:]]{8})' | tr 'a-z' 'A-Z'`
ACCOUNT2=`echo $accountinput | tr 'A-Z' 'a-z'`
#export TOWERRANK=`echo "$ADDRESSLIST" | grep -n "$ACCOUNT" | awk -F: '{print $1}'`
#export FULLACCOUNT=`echo "$ADDRESSLIST" | grep "$ACCOUNT"`
BALANCE=$(/home/ubuntu/libra-framework/target/release/libra query balance --account 0x$accountinput | jq -r '.unlocked, .total' | paste -sd " / ")
sleep 0.3
if [[ -z "$BALANCE" ]]; then
  BALANCE="Failed to get balance.."
else
  BALANCE2=$(echo $BALANCE | awk '{printf "%'\''d %'\''d", $1, $2}')
fi
export VSET=`echo "$ADDRESSLIST"`
if [ "$VSET" -lt 3 ] || [ -z "$VSET" ]; then
  VSET=""
else
  VSET="_ $VSET nodes"
fi
ufw deny 9101 > /dev/null; lock=":lock:"
send_discord_message() {
  local message=$1
  curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
}
while true; do
  EPOCH=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_consensus_epoch | grep -o '[0-9]*'`
  sleep 0.3
  if [[ -z "$EPOCH" ]]; then EPOCH=0; fi
  ROUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_consensus_current_round " | grep -o '[0-9]*'`
  sleep 0.3
  VOTEDROUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep last_voted_round | grep $accountinput | awk -F' ' '{print $2}'`
  sleep 0.3
  SYNC=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*'`
  sleep 0.3
  TARG=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_data_client_highest_advertised_data{data_type=\"ledger_infos\"} | grep -o '[0-9]*'`
  sleep 0.3
  if [ -z "$SYNC" ]; then SYNC=$TARG; fi
  LAG=`expr $TARG - $SYNC`
  sleep 1
  if [[ "$LAG" -le 0 ]]; then
    if [[ "$LAG" -lt 0 ]]; then
      Lag=""
      LAGK=""
    else
      Lag="_ Synced!"
      LAGK=""
    fi
  else
    Lag="_ Lag"
    if [[ "$LAG" -ge 1000 ]]; then
      LAGK=$(echo "scale=1; $LAG / 1000" | bc)K
    else
      LAGK=$(echo "scale=0; $LAG" | bc)
    fi
  fi
  if [ -n "$SYNC" ] && [ "$SYNC" -ne 0 ]; then
    if [[ "$SYNC" -gt 1000 ]]; then
      SYNCK=$(echo "scale=1; $SYNC / 1000" | bc)K
    else
      SYNCK=$(echo "scale=0; $SYNC / 10" | bc)
    fi
  fi
  sleep 0.3
  VOTE=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_commit_vote\",result=\"success\" | grep -o '[0-9]*'`
  sleep 0.3
  if [[ -z "$VOTE" ]]; then VOTE=0; fi
  if [[ -z "$prev_vote_reset" ]]; then prev_vote_reset=0; fi
  VOTE=`expr $VOTE - $prev_vote_reset`
  if [[ -z "$VOTE" ]]; then VOTE=0; fi
  sleep 0.3
  PROPOSAL=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_proposal\",result=\"success\" | grep -o '[0-9]*'`
  sleep 0.3
  PROOF=`tac /home/ubuntu/.libra/logs/tower.log | grep -m1 -oE '# [0-9]+' | grep -oE '[0-9]+$'`
  sleep 0.3
  BLOCKLIGHT=":green_circle:"
  VOTELIGHT=":green_circle:"
  SYNCLIGHT=":green_circle:"
  TOWERLIGHT=":green_circle:"
  sleep 0.3
  BALANCE=$(/home/ubuntu/libra-framework/target/release/libra query balance --account 0x$accountinput | jq -r '.unlocked, .total' | paste -sd " / ")
  sleep 0.3
  output=$(free)
  used_mem=$(echo "$output" | awk 'NR==2 {print $2}')
  available_mem=$(echo "$output" | awk 'NR==2 {print $7}')
  diff_mem=$((used_mem - available_mem))
  usedmem=$(awk "BEGIN { printf \"%.0f\", 100 * $diff_mem / $used_mem }")
  USEDMEM=$(echo "$usedmem" | sed 's/^0/0./')
  if (( $(echo "$USEDMEM >= 80.00" | bc -l) )); then
      NEEDCHECK=":thinking:"
  else
      NEEDCHECK=""
  fi
  send_discord_message() {
    local message=$1
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
  }
  if (( $(echo "$USEDMEM >= 85.00" | bc -l) )); then
      message="\`\n==================================\nAlert!! The memory usage is too high.\`  :astonished:\`\nDB regen is required. Restoring now...\`"
      send_discord_message "$message"
      PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null
      sleep 10
      sudo -u ubuntu tmux send-keys -t validator:0 'ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}' || cd /home/ubuntu/epoch-archive-testnet && make wipe-db && make restore-all && ulimit -n 1048576 && /home/ubuntu/libra-framework/target/release/libra node --config-path /home/ubuntu/.libra/validator.yaml >> /home/ubuntu/.libra/logs/validator.log 2>&1' C-m
      sleep 20
      restorecount=$((restorecount + 1))
      restart_flag=1
      PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && message="\`\n\`:fist:  \`Validator has been restored and restarted!!\`  :fist:\`\n==================================\`"
      sleep 1
      PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') || message="\`\nValidator failed to restart!! You need to check it.\`  :scream: :scream_cat:\`\n==================================\`"
      send_discord_message "$message"
      ufw deny 9101 > /dev/null; lock=":lock:"
  fi
  output=$(df / -h)
  used_space=$(echo "$output" | awk 'NR==2 {print $2}' | sed 's/G//')
  available_space=$(echo "$output" | awk 'NR==2 {print $4}' | sed 's/G//')
  diff_space=$((used_space - available_space))
  size=$(awk "BEGIN { printf \"%.0f\", 100 * $diff_space / $used_space }")
  SIZE=$(echo "$size" | sed 's/^0/0./')
  if (( $(echo "$SIZE >= 92.00" | bc -l) )); then
      NEEDCHECK2=":thinking:"
  else
      NEEDCHECK2=""
  fi
  CPU=$(mpstat | tail -1 | awk '{printf "%.0f", 100-$NF}')
  if [ -z "$ROUND" ]; then ROUND=0; fi
  if [ -z "$SYNC" ]; then SYNC=0; fi
  if [ -z "$VOTE" ]; then VOTE=0; fi
  if [ -z "$PROPOSAL" ]; then PROPOSAL=0; fi
  if [ -z "$PROOF" ]; then PROOF=0; fi
  ROUNDDIFF=`expr $ROUND - $prev_round`
  if [[ -z "$ROUNDDIFF" ]]; then ROUNDDIFF=0; fi
  SYNCDIFF=`expr $SYNC - $prev_sync`
  VOTEDIFF=`expr $VOTE - $prev_vote`
  if [[ -z "$VOTEDIFF" ]]; then VOTEDIFF=0; fi
  if [[ "$VOTEDIFF" -lt 0 ]]; then
    VOTEDIFF="$VOTE"
  fi
  PROPOSALDIFF=`expr $PROPOSAL - $prev_proposal`
  if [ -z "$ROUNDDIFF" ]; then ROUNDDIFF=0; fi
  if [ -z "$VOTEDIFF" ]; then VOTEDIFF=0; fi
  if [[ $ROUNDDIFF -eq 0 ]]; then
    :
  else
    if [[ $VOTEDIFF -lt 0 ]]; then VOTEDIFF=0; fi
    VSUCCESS=$(printf "%0.0f" "$(echo "scale=1; ($VOTEDIFF * 100) / $ROUNDDIFF" | bc)")
  fi
  sleep 0.3
  if [[ $prev_round == $ROUND ]]; then
    BLOCK1=$(curl -s https://testnet-rpc.openlibra.space:8080/v1 | grep -o '"ledger_version":"[0-9]*' | awk -F ':"' '{print $2}')
    sleep 20
    if [ -z "$BLOCK1" ]; then BLOCK1=0; fi
    sleep 2
    BLOCK2=$(curl -s https://testnet-rpc.openlibra.space:8080/v1 | grep -o '"ledger_version":"[0-9]*' | awk -F ':"' '{print $2}')
    sleep 20
    if [ -z "$BLOCK2" ]; then BLOCK2=0; fi
    sleep 2
    if [ -z "$BLOCK3" ]; then BLOCK3=0; fi
    sleep 2
    if [[ "$SYNC" == "$prev_sync" ]] && [[ "LAG" -lt 10 ]]
    then
      if [[ "$BLOCK2" == "$BLOCK1" ]] || [[ "$BLOCK1" == "$BLOCK3" ]] || [[ "$BLOCK2" == "$BLOCK3" ]]
      then
        if [ -z "$start_time" ]; then
          hourglass=""
          JUMPTIME=""
        else
          hourglass=":watch:"
          current_time=$(date +%s)
          time_difference=$((current_time - start_time))
          days=$((time_difference / 86400))
          hours=$(( (time_difference % 86400) / 3600 ))
          minutes=$(( (time_difference % 3600) / 60 ))
          days=$(printf "%02d" $days)
          hours=$(printf "%02d" $hours)
          minutes=$(printf "%02d" $minutes)
          export JUMPTIME=`echo "${days}d ${hours}h ${minutes}m"`
        fi
        unchanged_counter=$((unchanged_counter + 1))
        changed_counter=0
        if [[ $BLOCK2 -eq 0 ]]; then
          BLOCKCOMMENT="0lexplorer isn't responding."
        fi
        BLOCKLIGHT=":red_circle:"
        #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
        TOWERLIGHT=":zzz:"
        if [[ $SYNCDIFF -eq 0 ]]; then
          SYNCLIGHT=":red_circle:"
        else
          SYNCLIGHT=":green_circle:"
        fi
        if [[ $VOTEDIFF -eq 0 ]]; then
          VOTELIGHT=":red_circle:"
        else
          VOTELIGHT=":green_circle:"
        fi
        ufw allow 9101 > /dev/null; lock=":unlock:"
        if [ -z "$ROUND" ]; then ROUND=0; fi
        if [ -z "$VOTEDROUND" ]; then VOTEDROUND=0; fi
        RLAG=`expr $ROUND - $VOTEDROUND`
        if [[ $ROUND -ne $VOTEDROUND ]]; then
          RLag="Lag"
          ONROUND=":astonished:"
        else
          ONROUND=""
          RLag="On the final round."
          RLAG=""
        fi
        if [[ -z "$SYNC" ]]; then SYNC=0; fi
        if [[ -z "$BLOCK2" ]]; then BLOCK2=0; fi
        if [[ "$BLOCK2" -eq 0 ]]; then
          BLOCK2=""
        else
          (( LAG = BLOCK2 - SYNC ))
          if [[ "$LAG" -le 0 ]]; then
            if [[ "$LAG" -lt 0 ]]; then
              Lag=""
              LAGK=""
            else
              Lag="_ Synced!"
              LAGK=""
            fi
          else
            Lag="_ Lag"
            if [[ "$LAG" -ge 1000 ]]; then
              LAGK=$(echo "scale=1; $LAG / 1000" | bc)K
            else
              LAGK=$(echo "scale=0; $LAG" | bc)
            fi
          fi
          if [ -n "$SYNC" ] && [ "$SYNC" -ne 0 ]; then
            if [[ "$SYNC" -gt 1000 ]]; then
              SYNCK=$(echo "scale=1; $SYNC / 1000" | bc)K
            else
              SYNCK=$(echo "scale=0; $SYNC / 10" | bc)
            fi
          fi
        fi
        if [[ "$fullnode" -eq 1 ]]; then
          if [[ $SYNCDIFF -eq 0 ]]; then
            SYNCLIGHT=":red_circle:"
            #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            TOWERLIGHT=":zzz:"
            ufw allow 9101 > /dev/null; lock=":unlock:"
          else
            SYNCLIGHT=":green_circle:"
            #sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
            TOWERLIGHT=":green_circle:"
            ufw deny 9101 > /dev/null; lock=":lock:"
          fi
          send_discord_message() {
            local message=$1
            curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
          }
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT\`\nSync  : $SYNC $Lag $LAGK\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\` $TOWERLIGHT\` \nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        else
          send_discord_message() {
            local message=$1
            curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
          }
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH $VSET\`  $hourglass\` $JUMPTIME\nVer.  : $BLOCK2$BLOCKCOMMENT\nSync  : $SYNC $Lag $LAGK\nRound : $VOTEDROUND _ $RLag $RLAG\` $ONROUND\`\nVote  : $VOTE _ Voting stopped..\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\`"
          send_discord_message "$message"
          BLOCK2=""
          BLOCKCOMMENT=""
          message_printed=$((message_printed + 1))
          BLOCK3=$(curl -s https://testnet-rpc.openlibra.space:8080/v1 | grep -o '"ledger_version":"[0-9]*' | awk -F ':"' '{print $2}')
          sleep 40
        fi
      else
        send_discord_message() {
          local message=$1
          curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
        }
        message="\`\n==================================\nAlert!! Validator is not syncing.\`  :astonished:\`\nPreparing to restart...\`"
        send_discord_message "$message"
        PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null
        sleep 10
        sudo -u ubuntu tmux send-keys -t validator:0 'ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}' || ulimit -n 100000 && cat /dev/null > validator.log && /home/ubuntu/libra-framework/target/release/libra node --config-path /home/ubuntu/.libra/validator.yaml >> /home/ubuntu/.libra/logs/validator.log 2>&1' C-m
        sleep 6
        restartcount=$((restartcount + 1))
        PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && message="\`\nValidator restarted successfully!\`  :sunglasses:\`\n==================================\`"
        sleep 3
        PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') || message="\`\nValidator failed to restart!! You need to check it.\`  :scream: :scream_cat:\`\n==================================\`"
        send_discord_message "$message"
        restart_flag=1
      fi
    else
      if [ -z "$start_time" ]; then
        hourglass=""
        JUMPTIME=""
      else
        hourglass=":watch:"
        current_time=$(date +%s)
        time_difference=$((current_time - start_time))
        days=$((time_difference / 86400))
        hours=$(( (time_difference % 86400) / 3600 ))
        minutes=$(( (time_difference % 3600) / 60 ))
        days=$(printf "%02d" $days)
        hours=$(printf "%02d" $hours)
        minutes=$(printf "%02d" $minutes)
        export JUMPTIME=`echo "${days}d ${hours}h ${minutes}m"`
      fi
      BLOCKLIGHT=":green_circle:"
      if [[ $SYNCDIFF -eq 0 ]]; then
        SYNCLIGHT=":red_circle:"
        #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
        TOWERLIGHT=":zzz:"
      else
        SYNCLIGHT=":green_circle:"
      fi
      if [[ $VOTEDIFF -eq 0 ]]; then
        VOTELIGHT=":red_circle:"
      else
        VOTELIGHT=":green_circle:"
      fi
      if [ -z "$ROUND" ]; then ROUND=0; fi
      if [ -z "$VOTEDROUND" ]; then VOTEDROUND=0; fi
      RLAG=`expr $ROUND - $VOTEDROUND`
      if [[ $ROUND -ne $VOTEDROUND ]]; then
        RLag="Lag"
        ONROUND=":astonished:"
      else
        ONROUND=""
        RLag="On the final round."
        RLAG=""
      fi
      if [[ "$LAG" -lt 200 ]]; then
        if [[ "$fullnode" -eq 1 ]]; then
          if [[ $SYNCDIFF -eq 0 ]]; then
            SYNCLIGHT=":red_circle:"
            #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            TOWERLIGHT=":zzz:"
            ufw allow 9101 > /dev/null; lock=":unlock:"
          else
            SYNCLIGHT=":green_circle:"
            #sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
            TOWERLIGHT=":green_circle:"
            ufw deny 9101 > /dev/null; lock=":lock:"
          fi
          send_discord_message() {
            local message=$1
            curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
          }
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT\`\nSync  : $SYNC $Lag $LAGK\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\` $TOWERLIGHT\` \nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        else
          send_discord_message() {
            local message=$1
            curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
          }
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH $VSET\`  $hourglass\` $JUMPTIME\nVer.  : $BLOCK2$BLOCKCOMMENT\nSync  : $SYNC $Lag $LAGK\nRound : $VOTEDROUND _ $RLag $RLAG\` $ONROUND\`\nVote  : $VOTE\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\`"
          message="\`\n==================================\nAlert!! Validator is not voting.\`  :astonished:\`\nPreparing to restart...\`"
          send_discord_message "$message"
          BLOCK2=""
          BLOCKCOMMENT=""
          PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null
          sleep 10
          sudo -u ubuntu tmux send-keys -t validator:0 'ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}' || ulimit -n 100000 && cat /dev/null > validator.log && /home/ubuntu/libra-framework/target/release/libra node --config-path /home/ubuntu/.libra/validator.yaml >> /home/ubuntu/.libra/logs/validator.log 2>&1' C-m
          sleep 6
          restartcount=$((restartcount + 1))
          if [ -z "$VSUCCESS" ]; then VSUCCESS=0; fi
          sleep 0.5
          if (( $(echo "$VSUCCESS < 1" | bc -l) )); then
            #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            FAST2=":exclamation:"
          else
            QQ=`ps -ef | grep tower | awk 'NR==1 {print $2}'`
            if [ -z "$QQ" ]; then
              if [[ "$fullnode" -eq 0 ]]; then
                sudo -u ubuntu tmux send-keys -t tower:0 'nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
              fi
            fi
          fi
          sleep 1
          PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && message="\`\nValidator restarted successfully!\`  :sunglasses:\`\n==================================\`"
          sleep 3
          PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') || message="\`\nValidator failed to restart!! You need to check it.\`  :scream: :scream_cat:\`\n==================================\`"
          send_discord_message "$message"
          restart_flag=1
        fi
      else
        Lag="Lag"
        if [ -z "$prev_sync" ]; then prev_sync=$SYNC; fi
        LDIFF=`expr $SYNC - $prev_sync`
        if [ -z "$LDIFF" ]; then LDIFF=0; fi
        if [[ $LDIFF -lt 0 ]]; then LDIFF=0; fi
        LTPS=$(printf "%0.2f" "$(echo "scale=2; $LDIFF / 660" | bc)")
        LTPS2="_ $LTPS[TPS]"
        SPEED=$(echo "scale=2; $LTPS" | bc)
        CATCHUP=$(printf "%0.2f" "$(echo "scale=2; ( $LAG / $SPEED ) / 3600" | bc)")
        if [[ "$BLOCK2" == "$BLOCK1" ]] || [[ "$BLOCK1" == "$BLOCK3" ]] || [[ "$BLOCK2" == "$BLOCK3" ]]; then
          BLOCKLIGHT=":red_circle:"
        else
          BLOCKLIGHT=":green_circle:"
        fi
        send_discord_message() {
          local message=$1
          curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
        }
        message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH $VSET\`  $hourglass\` $JUMPTIME\nVer.  : $BLOCK2$BLOCKCOMMENT\nSync  : $Lag $LAGK _ ETA $CATCHUP[Hr]\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\`"
        send_discord_message "$message"
        BLOCK2=""
        BLOCKCOMMENT=""
        if [ -z "$VSUCCESS" ]; then VSUCCESS=0; fi
        sleep 0.5
        if (( $(echo "$VSUCCESS < 1" | bc -l) )); then
          #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
          FAST2=":exclamation:"
        else
          QQ=`ps -ef | grep tower | awk 'NR==1 {print $2}'`
          if [ -z "$QQ" ]; then
            if [[ "$fullnode" -eq 0 ]]; then
              sudo -u ubuntu tmux send-keys -t tower:0 'nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
            fi
          fi
        fi
      fi
    fi
  else
    changed_counter=$((changed_counter + 1))
    unchanged_counter=0
    if [ -z "$prev_sync" ]; then prev_sync=$SYNC; fi
    LDIFF=`expr $SYNC - $prev_sync`
    if [ -z "$LDIFF" ]; then LDIFF=0; fi
    if [[ $LDIFF -lt 0 ]]; then LDIFF=0; fi
    if [[ $LDIFF -eq 0 ]]; then
      BLOCKLIGHT=":red_circle:"
      #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
      TOWERLIGHT=":zzz:"
    fi
    LTPS=$(printf "%0.2f" "$(echo "scale=2; $LDIFF / 660" | bc)")
    LTPS2="_ $LTPS[TPS]"
    if [ -z "$prev_round" ]; then prev_round=$ROUND; fi 
    ROUNDDIFF=`expr $ROUND - $prev_round`
    if [ -z "$ROUNDDIFF" ]; then ROUNDDIFF=0; fi
    if [ "$ROUNDDIFF" -gt 1300 ]; then
      FAST=":sparkly:"
    else
      FAST=""
    fi
    if [ -z "$prev_vote" ]; then prev_vote=$VOTE; fi 
    VOTEDIFF=`expr $VOTE - $prev_vote`
    if [[ "$VOTEDIFF" -lt 0 ]]; then VOTEDIFF="$VOTE"; fi
    if [ -z "$VOTEDIFF" ]; then VOTEDIFF=0; fi
    if [ "$VOTEDIFF" -gt 1300 ]; then
      VOTELIGHT=":green_circle:"
      FAST2=":sparkly:"
    else
      if [ "$VOTEDIFF" -eq 0 ]; then
        VOTELIGHT=":red_circle:"
        FAST2=""
      else
        VOTELIGHT=":green_circle:"
        FAST2=""
      fi
    fi
    if (( $(echo "$VSUCCESS < 70" | bc -l) ))
    then
      FAST2=":exclamation:"
      #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
      TOWERLIGHT=":zzz:"
    else
      if [ "$VOTEDIFF" -gt 1300 ]; then
        FAST2=":sparkly:"
      else
        FAST2=""
      fi
      QQ=`ps -ef | grep tower | awk 'NR==1 {print $2}'`
      if [ -z "$QQ" ]; then
        if [[ "$fullnode" -eq 0 ]]; then
          sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
        fi
      fi
    fi
    RTPS=$(printf "%0.1f" "$(echo "scale=2; $ROUNDDIFF / 600" | bc)")
    QQ=`ps -ef | grep tower | awk 'NR==1 {print $2}'`
    if [[ $EPOCH -gt $prev_epoch ]] && [[ $EPOCH -ne 0 ]] && [[ $prev_epoch -ne 0 ]]; then
      if [[ "$LAG" -le 0 ]]; then
        if [[ "$LAG" -lt 0 ]]; then
          Lag=""
          LAGK=""
        else
          Lag="_ Synced!"
          LAGK=""
        fi
      else
        Lag="_ Lag"
        if [[ "$LAG" -ge 1000 ]]; then
          LAGK=$(echo "scale=1; $LAG / 1000" | bc)K
        else
          LAGK=$(echo "scale=0; $LAG" | bc)
        fi
      fi
      if [ -n "$SYNC" ] && [ "$SYNC" -ne 0 ]; then
        if [[ "$SYNC" -gt 1000 ]]; then
          SYNCK=$(echo "scale=1; $SYNC / 1000" | bc)K
        else
          SYNCK=$(echo "scale=0; $SYNC / 10" | bc)
        fi
      fi
      ADDRESSLIST=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep 'diem_all_validators_voting_power{peer_id=' | awk -F'"' '{print $2}' | tr ' ' '\n' | wc -l`
      #ACCOUNT=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections\{direction=\"inbound\",network_id=\"Validator\",peer_id= | grep -oE '([[:xdigit:]]{8})' | tr 'a-z' 'A-Z'`
      ACCOUNT2=`echo $accountinput | tr 'A-Z' 'a-z'`
      #export TOWERRANK=`echo "$ADDRESSLIST" | grep -n "$ACCOUNT" | awk -F: '{print $1}'`
      #export FULLACCOUNT=`echo "$ADDRESSLIST" | grep "$ACCOUNT"`
      BALANCE=$(/home/ubuntu/libra-framework/target/release/libra query balance --account 0x$accountinput | jq -r '.unlocked, .total' | paste -sd " / ")
      sleep 0.3
      if [[ -z "$BALANCE" ]]; then
        BALANCE="Failed to get balance.."
      else
        BALANCE2=$(echo $BALANCE | awk '{printf "%'\''d %'\''d", $1, $2}')
      fi
      export VSET=`echo "$ADDRESSLIST"`
      if [ "$VSET" -lt 3 ] || [ -z "$VSET" ]; then
        VSET=""
      else
        VSET="_ $VSET nodes"
      fi
      sleep 0.3
      if [[ -z $TOWERRANK ]]; then
        RANK=""
        TOWERRANK=""
      else
        RANK="Power Ranking"
      fi
      VOTE=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_commit_vote\",result=\"success\" | grep -o '[0-9]*'`
      if [[ $ROUNDDIFF -eq 0 ]]; then
        :
      else
        if [[ $VOTEDIFF -lt 0 ]]; then VOTEDIFF=0; fi
        VSUCCESS=$(printf "%0.0f" "$(echo "scale=1; ($VOTEDIFF * 100) / $ROUNDDIFF" | bc)")
      fi
      export start_time=$(date +%s)
      hourglass=":watch:"
      firstepoch=1
      if [[ $SYNCDIFF -eq 0 ]]; then
        SYNCLIGHT=":red_circle:"
        #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
        TOWERLIGHT=":zzz:"
        ufw allow 9101 > /dev/null; lock=":unlock:"
      else
        SYNCLIGHT=":green_circle:"
        if [[ "$fullnode" -eq 0 ]]; then
          sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
        fi
        TOWERLIGHT=":green_circle:"
        ufw deny 9101 > /dev/null; lock=":lock:"
      fi
      restartcount=0 && restorecount=0 &&
      message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH  New epoch started!\`  :fist::high_brightness:\`\nSync  : $SYNC $Lag $LAGK\` $LAGCHECK\`\nRound : $ROUND\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\` $TOWERLIGHT\` $RANK $TOWERRANK\nBal.  : $BALANCE2\`"
      send_discord_message "$message"
    else
      if [ -z "$start_time" ]; then
        hourglass=""
        JUMPTIME=""
      else
        hourglass=":watch:"
        current_time=$(date +%s)
        time_difference=$((current_time - start_time))
        days=$((time_difference / 86400))
        hours=$(( (time_difference % 86400) / 3600 ))
        minutes=$(( (time_difference % 3600) / 60 ))
        days=$(printf "%02d" $days)
        hours=$(printf "%02d" $hours)
        minutes=$(printf "%02d" $minutes)
        export JUMPTIME=`echo "${days}d ${hours}h ${minutes}m"`
      fi
      if [[ $scriptstart -eq 0 ]]; then
        prev_vote_reset="$VOTE"
      ADDRESSLIST=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep 'diem_all_validators_voting_power{peer_id=' | awk -F'"' '{print $2}' | tr ' ' '\n' | wc -l`
      #ACCOUNT=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_connections\{direction=\"inbound\",network_id=\"Validator\",peer_id= | grep -oE '([[:xdigit:]]{8})' | tr 'a-z' 'A-Z'`
      ACCOUNT2=`echo $accountinput | tr 'A-Z' 'a-z'`
      #export TOWERRANK=`echo "$ADDRESSLIST" | grep -n "$ACCOUNT" | awk -F: '{print $1}'`
      #export FULLACCOUNT=`echo "$ADDRESSLIST" | grep "$ACCOUNT"`
        BALANCE=$(/home/ubuntu/libra-framework/target/release/libra query balance --account 0x$accountinput | jq -r '.unlocked, .total' | paste -sd " / ")
        sleep 0.3
        if [[ -z "$BALANCE" ]]; then
          BALANCE="Failed to get balance.."
        else
          BALANCE2=$(echo $BALANCE | awk '{printf "%'\''d %'\''d", $1, $2}')
        fi
        export VSET=`echo "$ADDRESSLIST"`
        if [ "$VSET" -lt 3 ] || [ -z "$VSET" ]; then
          VSET=""
        else
          VSET="_ $VSET nodes"
        fi
        sleep 0.3
        if [[ -z $TOWERRANK ]]; then
          RANK=""
          TOWERRANK=""
        else
          RANK="Power Ranking"
        fi
        if [[ $SYNCDIFF -eq 0 ]]; then
          SYNCLIGHT=":red_circle:"
          #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
          TOWERLIGHT=":zzz:"
          ufw allow 9101 > /dev/null; lock=":unlock:"
        else
          SYNCLIGHT=":green_circle:"
          if [[ "$fullnode" -eq 0 ]]; then
            sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
          fi
          TOWERLIGHT=":green_circle:"
          ufw deny 9101 > /dev/null; lock=":lock:"
        fi
        if [[ "$fullnode" -eq 1 ]]; then
          message="\`\nScript started!\`  :robot:\`\nSync  : $SYNC $Lag $LAGK\nRound : You're not in validator set.\nVote  : You're not in validator set.\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        else
          message="\`\nScript started!\`  :robot:\`\nEpoch : $EPOCH $VSET\`  $hourglass\` $JUMPTIME\nSync  : $SYNC $Lag $LAGK\nRound : $ROUND\nVote  : Calculating from now on.\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        fi
        scriptstart=1
      else
        if [[ $firstepoch -eq 0 ]]; then
          if [[ $SYNCDIFF -eq 0 ]]; then
            SYNCLIGHT=":red_circle:"
            #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            TOWERLIGHT=":zzz:"
            ufw allow 9101 > /dev/null; lock=":unlock:"
          else
            SYNCLIGHT=":green_circle:"
            if [[ "$fullnode" -eq 0 ]]; then
              sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
            fi
            TOWERLIGHT=":green_circle:"
            ufw deny 9101 > /dev/null; lock=":lock:"
          fi
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH $VSET\`  $hourglass\` $JUMPTIME\nSync  : $SYNC $LTPS2 $Lag $LAGK\nRound : +$ROUNDDIFF > $ROUND _ $RTPS[δr/s]\` $FAST\`\nVote  : +$VOTEDIFF > $VOTE _ $VSUCCESS%[δv/δr]\` $FAST2\`\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\` $TOWERLIGHT\` $RANK $TOWERRANK\nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        else
          if [[ $SYNCDIFF -eq 0 ]]; then
            SYNCLIGHT=":red_circle:"
            #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            TOWERLIGHT=":zzz:"
            ufw allow 9101 > /dev/null; lock=":unlock:"
          else
            SYNCLIGHT=":green_circle:"
            if [[ "$fullnode" -eq 0 ]]; then
              sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
            fi
            TOWERLIGHT=":green_circle:"
            ufw deny 9101 > /dev/null; lock=":lock:"
          fi
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH $VSET\`  $hourglass\` $JUMPTIME\nSync  : $SYNC $LTPS2 $Lag $LAGK\nRound : +$ROUNDDIFF > $ROUND _ $RTPS[δr/s]\` $FAST\`\nVote  : +$VOTEDIFF > $VOTE _ $VSUCCESS%[δv/δr]\` $FAST2\`\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\` $TOWERLIGHT\` $RANK $TOWERRANK\nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        fi
      fi
    fi
  fi
  if [[ $ROUND -lt $prev_round ]] && [[ $EPOCH -ne 0 ]] && [[ $EPOCH -ne $prev_epoch ]]; then
    firstepoch=1
    restart_flag=0
    refresh3="$PROOF"
    prev_epoch="$EPOCH"
    prev_vote="$VOTE"
    prev_vote_reset="$VOTE"
    prev_round=0
    PROPOSAL=0
    prev_proposal="$PROPOSAL"
    prev_proof=`expr $PROOF - $refresh3`
    setcheck=0
  else
    if [[ $restart_flag -eq 1 ]]; then
      prev_vote="$VOTE"
      prev_vote_reset=0
      prev_proposal="$PROPOSAL"
      prev_proof=`expr $PROOF - $refresh3`
      setcheck=$((setcheck + 1))
      restart_flag=0
    else
      prev_round="$ROUND"
      prev_epoch="$EPOCH"
      prev_vote="$VOTE"
      prev_proposal="$PROPOSAL"
      prev_proof=`expr $PROOF - $refresh3`
      setcheck=$((setcheck + 1))
    fi
  fi
  prev_round="$ROUND"
  prev_sync="$SYNC"
  VOTERECHECK=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_safety_rules_queries\{method=\"sign_commit_vote\",result=\"success\"`
  if [[ $unchanged_counter -ge 1 ]] && [[ $message_printed -ge 1 ]]; then
    if [[ $SYNC -eq 0 ]] && [[ -z $VOTERECHECK ]] && [[ $PROPOSAL -eq 0 ]]; then
      :
    else
      restart_message_printed=0
      message_printed=0
      consensus_restart=1
      ROUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep "diem_consensus_current_round " | grep -o '[0-9]*'`
      VOTEDROUND=`curl 127.0.0.1:9101/metrics 2> /dev/null | grep last_voted_round | grep $accountinput | awk -F' ' '{print $2}'`
      if [ -z "$VOTEDROUND" ]; then VOTEDROUND=0; fi
      if [ -z "$ROUND" ]; then ROUND=0; fi
      sleep 0.5
      if [[ "$ROUND" -gt "$VOTEDROUND" ]] && [[ "$SYNCDIFF" -eq 0 ]]; then
        if [[ "$fullnode" -eq 1 ]]; then
          if [[ $SYNCDIFF -eq 0 ]]; then
            SYNCLIGHT=":red_circle:"
            #PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep tower | awk 'NR==1 {print $2}') && kill -TERM $PID &> /dev/null
            TOWERLIGHT=":zzz:"
            ufw allow 9101 > /dev/null; lock=":unlock:"
          else
            SYNCLIGHT=":green_circle:"
            if [[ "$fullnode" -eq 0 ]]; then
              sudo -u ubuntu tmux send-keys -t tower:0 'ps -ef | grep tower | awk 'NR==1 {print $2}' || nohup /home/ubuntu/libra-framework/target/release/libra tower start >> /home/ubuntu/.libra/logs/tower.log &' C-m
            fi
            TOWERLIGHT=":green_circle:"
            ufw deny 9101 > /dev/null; lock=":lock:"
          fi
          send_discord_message() {
            local message=$1
            curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
          }
          message="\`\nBlock\` $BLOCKLIGHT   \`Sync\` $SYNCLIGHT   \`Vote\` $VOTELIGHT\`\nEpoch : $EPOCH \nSync  : $SYNC $Lag $LAGK\nStat  : CPU $CPU%  MEM $USEDMEM%\` $NEEDCHECK\` VOL $SIZE%\` $NEEDCHECK2\`\nCount : Restarted $restartcount _ Restored $restorecount\nTower : $PROOF\` $TOWERLIGHT\` \nBal.  : $BALANCE2\`"
          send_discord_message "$message"
        else
          send_discord_message() {
            local message=$1
            curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
          }
          message="\`\n==================================\nYou're not on the latest round.\`  :astonished:\`\nPreparing to restart...\`"
          send_discord_message "$message"
          PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null
          sleep 10
          sudo -u ubuntu tmux send-keys -t validator:0 'ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}' || ulimit -n 100000 && cat /dev/null > validator.log && /home/ubuntu/libra-framework/target/release/libra node --config-path /home/ubuntu/.libra/validator.yaml >> /home/ubuntu/.libra/logs/validator.log 2>&1' C-m
          sleep 6
          restartcount=$((restartcount + 1))
          restart_flag=1
          PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && message="\`\nValidator restarted successfully!\`  :sunglasses:\`\n==================================\`"
          sleep 3
          PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') || message="\`\nValidator failed to restart!! You need to check it.\`  :scream: :scream_cat:\`\n==================================\`"
          send_discord_message "$message"
        fi
      fi
    fi
  fi
  if [ -z "$SYNC" ]; then SYNC=0; fi
  if [ -z "$ROUND" ]; then ROUND=0; fi
  if [ -z "$VOTE" ]; then VOTE=0; fi
  if [ -z "$PROPOSAL" ]; then PROPOSAL=0; fi
  if [[ $SYNC -eq 0 ]] && [[ -z $VOTERECHECK ]] && [[ $PROPOSAL -eq 0 ]]; then
    RESTORECHECK=$((RESTORECHECK + 1))
    if [[ $RESTORECHECK -eq 2 ]]; then
      message="\`\n==================================\nAlert!! Can't get data from DB.\`  :astonished:\`\nDB regen is required. Restoring now...\`"
      send_discord_message "$message"
      PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null && sleep 0.5 && PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && kill -TERM $PID &> /dev/null
      sleep 10
      sudo -u ubuntu tmux send-keys -t validator:0 'ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}' || cd /home/ubuntu/epoch-archive-testnet && make wipe-db && make restore-all && ulimit -n 1048576 && /home/ubuntu/libra-framework/target/release/libra node --config-path /home/ubuntu/.libra/validator.yaml >> /home/ubuntu/.libra/logs/validator.log 2>&1' C-m
      sleep 20
      restorecount=$((restorecount + 1))
      restart_flag=1
      send_discord_message() {
        local message=$1
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
      }
      PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') && message="\`\n\`:fist:  \`Validator has been restored and restarted!!\`  :fist:\`\n==================================\`"
      sleep 1
      PID=$(ps -ef | grep ".libra/validator.yaml" | awk 'NR==2 {print $2}') || message="\`\nValidator failed to restart!! You need to check it.\`  :scream: :scream_cat:\`\n==================================\`"
      send_discord_message "$message"
      sleep 1
      RESTORECHECK=0
    fi
  fi
  if [[ $changed_counter -ge 1 ]] && [[ $consensus_restart -eq 1 ]] && [[ $restart_message_printed -eq 0 ]] && [[ $SYNCDIFF -gt 0 ]]; then
    send_discord_message() {
      local message=$1
      curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
    }
    message="\`\n\`:airplane_departure:  \`Consensus restarted!\`  :airplane:"
    send_discord_message "$message"
    message_printed=0
    consensus_restart=0
    restart_message_printed=1
    delay=0
  fi
  # Wait for 10 minutes
  sleep 600
done