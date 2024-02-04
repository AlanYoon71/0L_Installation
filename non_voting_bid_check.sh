#!/bin/bash

libra query resource --resource-path-string 0x1::stake::ValidatorSet --account 0x1 | jq -r '.active_validators[].addr' > validators_in_set.txt
set_count=`cat validators_in_set.txt | wc -l`
libra query resource --resource-path-string 0x1::epoch_boundary::BoundaryStatus --account 0x1 | jq -r '.incoming_only_qualified_bidders' | jq -r '.[]' > val_universe.txt
echo ""
echo "Validators’ identities in set ( $set_count )"
echo "============================="
while IFS= read -r key; do
  val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
  first_col="${val:32:4}...${val:60:4}"
  second_col=$(awk '{print $2}' <<< "$val")
  echo "$first_col   $second_col"
done < validators_in_set.txt
echo "============================="

libra query resource --resource-path-string 0x1::stake::ValidatorPerformance --account 0x1 | jq -r '.validators[].successful_proposals' > result1.txt
sleep 120
libra query resource --resource-path-string 0x1::stake::ValidatorPerformance --account 0x1 | jq -r '.validators[].successful_proposals' > result2.txt
comm -12 <(sort result1.txt) <(sort result2.txt) > common_rows.txt
awk 'NR==FNR { a[$1]; next } FNR in a' common_rows.txt validators_in_set.txt > inactive_in_set.txt
inactive_count=`cat inactive_in_set.txt | wc -l`
if [[ $inactive_count -eq 0 ]]
then
  echo ""
  echo "All validators in set are proposing."
else
  echo ""
  echo "Inactive validators in set ( $inactive_count )"
  echo "=========================="
  while IFS= read -r key; do
    val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
    first_col="${val:32:4}...${val:60:4}"
    second_col=$(awk '{print $2}' <<< "$val")
    echo "$first_col   $second_col"
  done < inactive_in_set.txt
  echo "=========================="
fi

# libra query resource --resource-path-string 0x1::validator_universe::ValidatorUniverse --account 0x1 | jq -r '.validators' | jq -r '.[]' > val_universe.txt
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
#highest_bid_value=$(awk 'NR==1{max=$1} $1>max{max=$1; count=1} $1==max{count++} END{print max}' bid_list.txt)
#highest_bid_quantity=$(awk 'NR==1{max=$1} $1>max{max=$1; count=1} $1==max{count++} END{printf "%d\n", count-1}' bid_list.txt)

first_max=$(awk 'NR==1{max=$1} $1>max{max=$1; count=1} $1==max{count++} END{print max}' bid_list.txt)
echo "$first_max" > first_max.txt
second_max=$(awk -v first_max="$first_max" '$1<first_max{if($1>second_max) second_max=$1} END{print second_max}' bid_list.txt)
echo "$second_max" > second_max.txt
third_max=$(awk -v first_max="$first_max" -v second_max="$second_max" '$1<first_max && $1<second_max{if($1>third_max) third_max=$1} END{print third_max}' bid_list.txt)
echo "$third_max" > third_max.txt
first_max_count=$(awk -v first_max="$first_max" '$1==first_max{count++} END{print count}' bid_list.txt)
echo "$first_max_count" > first_max_count.txt
second_max_count=$(awk -v second_max="$second_max" '$1==second_max{count++} END{print count}' bid_list.txt)
echo "$second_max_count" > second_max_count.txt
third_max_count=$(awk -v third_max="$third_max" '$1==third_max{count++} END{print count}' bid_list.txt)
echo "$third_max_count" > third_max_count.txt

first_max_account=$(awk -v first_max="$first_max" '$1 == first_max {print $2}' bid_list.txt)
echo "$first_max_account" > first_max_account.txt
second_max_account=$(awk -v second_max="$second_max" '$1 == second_max {print $2}' bid_list.txt)
echo "$second_max_account" > second_max_account.txt
third_max_account=$(awk -v third_max="$third_max" '$1 == third_max {print $2}' bid_list.txt)
echo "$third_max_account" > third_max_account.txt

echo ""
echo "High bid validators outside set"
echo "=================================="
while IFS= read -r key; do
  val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
  first_col="${val:32:4}...${val:60:4}"
  second_col=$(awk '{print $2}' <<< "$val")
  echo "$first_col   $first_max   $second_col"
done < first_max_account.txt
while IFS= read -r key; do
  val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
  first_col="${val:32:4}...${val:60:4}"
  second_col=$(awk '{print $2}' <<< "$val")
  echo "$first_col   $second_max   $second_col"
done < second_max_account.txt
while IFS= read -r key; do
  val=$(grep -E "${key:0:6}|${key:1:6}|${key:2:6}|${key:3:6}|${key:4:6}|${key:5:6}" val_accounts_total.txt | awk '{print $1, $2}')
  first_col="${val:32:4}...${val:60:4}"
  second_col=$(awk '{print $2}' <<< "$val")
  echo "$first_col   $third_max   $second_col"
done < third_max_account.txt
echo "=================================="

echo "1st group : $first_max ( $first_max_count )"
echo "2nd group : $second_max ( $second_max_count )"
echo "3rd group : $third_max ( $third_max_count )"

echo "# Only qualified validators are considered."
sleep 2
while true; do
    echo ""
    echo ""
    echo "If you’d like to change your current bid value,"
    echo "input your 64-digit address(exclude ‘0x’) and bid value(ex. 100)."
    read -p "account   : " accountinput
    read -p "bid value : " input_value
    echo ""
    if [[ $accountinput =~ ^[A-Z0-9]{1,31}$ ]] || [[ -z $accountinput ]]; then
        echo "Input 64-digit full account address exactly, please."
        echo "If you want to stop proceed, simply press Ctrl+C. :)"
    else
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        echo "Your account is $accountinput. Accepted."
        echo "Input value is $input_value."
        read -p "Mnemonic  : " MNEMONIC
        sleep 1
        break
    fi
done
bid1=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
value_fix=$(echo "scale=3; $input_value / 1000" | bc)
expect <<EOF
spawn libra txs validator pof --bid-pct $value_fix --expiry 1000
expect "🔑"
send "$MNEMONIC\r"
expect eof
EOF
sleep 5
bid2=`libra query resource --resource-path-string 0x1::proof_of_fee::ProofOfFeeAuction --account $accountinput | jq -r '.bid' | tr -d '\"'`
if [[ $bid1 -eq $bid2 ]]
then
  echo ""
  echo "Bid value has not changed."
else
  echo ""
  echo "Bid value updated! $bid1 ----> $bid2"
fi
sleep 2
echo ""
echo ""
echo "Done!"