#!/bin/bash

libra query resource --resource-path-string 0x1::fee_maker::EpochFeeMakerRegistry --account 0x1 | jq -r '.fee_makers[]' > validators_in_set.txt
set_count=`cat validators_in_set.txt | wc -l`
libra query resource --resource-path-string 0x1::validator_universe::ValidatorUniverse --account 0x1 | jq -r '.validators' > val_universe.txt

echo ""
echo "Validators’ identities in set ( $set_count )"
echo "============================="
while IFS= read -r key; do
  val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
  first_col="${val:32:4}...${val:60:4}"
  second_col=$(awk '{print $2}' <<< "$val")
  echo "$first_col $second_col"
done < validators_in_set.txt
echo "=============================="

curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep last_voted_round{peer_id= > result1.txt
sleep 120
curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep last_voted_round{peer_id= > result2.txt
awk 'NR==FNR{a[$0]; next} !($0 in a)' result1.txt result2.txt > result2_filtered.txt
awk -F'peer_id="' '{print $2}' result2_filtered.txt | awk -F'"' '{print $1}' > result3.txt
awk 'NR==FNR{a[substr($0, length($0)-5)]; next} !(substr($0, length($0)-5) in a)' result3.txt validators_in_set.txt > inactive_in_set.txt
inactive_count=`cat inactive_in_set.txt | wc -l`
if [[ $inactive_count -eq 0 ]]
then
  echo ""
  echo "All validators are voting."
else
  echo ""
  echo "Inactive validators in set ( $inactive_count )"
  echo "=========================="
  while IFS= read -r key; do
    val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
    first_col="${val:32:4}...${val:60:4}"
    second_col=$(awk '{print $2}' <<< "$val")
    echo "$first_col $second_col"
  done < inactive_in_set.txt
  echo "==========================="
fi

libra query resource --resource-path-string 0x1::validator_universe::ValidatorUniverse --account 0x1 | jq -r '.validators' | jq -r '.[]' > val_universe.txt
grep -o -E '\w{6,}' val_universe.txt > val_universe_keys.txt
grep -o -E '\w{6,}' validators_in_set.txt > validators_in_set_keys.txt
grep -v -F -f validators_in_set_keys.txt val_universe_keys.txt > val_universe_filtered_keys.txt
grep -F -f val_universe_filtered_keys.txt val_universe.txt > val_universe_filtered.txt
mv val_universe_filtered.txt val_universe.txt
rm val_universe_keys.txt validators_in_set_keys.txt val_universe_filtered_keys.txt
keys=$(grep -o -E '\w+' val_universe.txt)
for key in $keys
do
    result=$(libra query resource --resource-path-string 0x1::jail::Jail --account $key | jq -r .is_jailed)
    if [ "$result" != "false" ]
    then
        sed -i "/$key/d" val_universe.txt
    fi
done
keys=$(grep -o -E '\w+' val_universe.txt)
for key in $keys
do
    result=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account $key | jq '.my_buddies | map(select(startswith("0x"))) | length')
    if [ "$result" -le 4 ]
    then
        sed -i "/$key/d" val_universe.txt
    fi
done
rm bid_list.txt;
readarray -t addresses < val_universe.txt
for address in "${addresses[@]}"; do
    result=$(libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $address | jq -r '.bid' | tr -d '\"')
    echo "$result $address" >> bid_list.txt
    sleep 3
done
highest_bid_value=$(awk 'NR==1{max=$1} $1>max{max=$1; count=1} $1==max{count++} END{print max}' bid_list.txt)
highest_bid_quantity=$(awk 'NR==1{max=$1} $1>max{max=$1; count=1} $1==max{count++} END{printf "%d\n", count-1}' bid_list.txt)
awk 'BEGIN {max = 0} {if ($1 > max) {max = $1; line = $0} else if ($1 == max) {line = line "\n" $0}} END {print line}' bid_list.txt | awk '{print $2}' > max_bid_list.txt
echo ""
echo "Highest bid validators outside set"
echo "=================================="
while IFS= read -r key; do
  val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
  first_col="${val:32:4}...${val:60:4}"
  second_col=$(awk '{print $2}' <<< "$val")
  echo "$first_col $second_col"
done < max_bid_list.txt
echo "=================================="
echo "Highest bid value(qty) : $highest_bid_value ( $highest_bid_quantity )"
echo ""
echo "# Only the bid values of eligible validators are considered."
while true; do
    echo ""
    echo "If you’d like your bid value to match the highest bid outside the set,"
    echo "please input your 64-digit validator account address (excluding ‘0x’)."
    read -p "account : " accountinput
    echo ""
    if [[ $accountinput =~ ^[A-Z0-9]{1,31}$ ]] || [[ -z $accountinput ]]; then
        echo "Input 64-digit full account address exactly, please."
        echo "If you want to skip this action, simply press Ctrl+C. :)"
    else
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        echo "Your account is $accountinput. Accepted."
        break
    fi
done
bid1=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
if [[ $bid1 -ge $highest_bid_value ]]
then
  :
else
  recommended_bid_value=$(echo "scale=3; $highest_bid_value / 1000" | bc)
  echo "Recommended bid value : $highest_bid_value"
  expect <<EOF
  spawn libra txs validator pof --bid-pct $recommended_bid_value --expiry 1000
  expect "🔑"
  send "$MNEMONIC\r"
  expect eof
EOF
  sleep 5
  bid2=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
  bid1=$(awk "BEGIN { printf \"%.1f\", $bid1 / 10 }") && bid1="$bid1%"
  bid2=$(awk "BEGIN { printf \"%.1f\", $bid2 / 10 }") && bid2="$bid2%"
  echo "Bid value updated! $bid1 ----> $bid2"
fi