#!/bin/bash

while true; do
    echo ""
    echo "Input 64-digit or 32-digit target account address. (exclude \"0x\")"
    read -p "account : " accountinput
    echo ""
    if [[ $accountinput =~ ^0x ]]; then
        echo "Do not include '0x' at the beginning of the account address. Please try again."
    elif [[ ${#accountinput} -ne 64 && ${#accountinput} -ne 32 ]]; then
        echo "Please input a 64-digit or 32-digit account address exactly."
    elif [[ ${#accountinput} -eq 32 ]]; then
        accountinput="00000000000000000000000000000000$accountinput"
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        echo "Target account is $accountinput. Accepted."
        echo ""
        echo ""
        break
    elif [[ ${#accountinput} -eq 64 ]]; then
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        echo "Target account is $accountinput. Accepted."
        echo ""
        echo ""
        break
    fi
done

EPOCH2=$(curl -s http://localhost:8080/v1/ | jq -r '.epoch') &> /dev/null
libra query resource --resource-path-string 0x1::validator_universe::ValidatorUniverse 0x1 | jq -r '.validators[]' > raw_val_universe.txt
sleep 0.5
libra query resource --resource-path-string 0x1::vouch::MyVouches $accountinput | jq -r --arg key "$accountinput" '.epoch_vouched as $epochs | .my_buddies as $buddies | [$epochs, $buddies] | transpose | map(.[1] | gsub("^0x"; "") | . as $orig | "0000000000000000000000000000000000000000000000000000000000000000\($orig)" | .[-64:] + " " + $key) | .[]' > my_vouchers_$EPOCH2.txt
voucher_count=$(cat my_vouchers_$EPOCH2.txt | wc -l)
echo -e "\e[1m\e[32mVouchers for Target Account\e[0m (From --> Target) Total \e[1m\e[32m$voucher_count\e[0m accounts"
echo "==============================================================="
cat "my_vouchers_$EPOCH2.txt"
echo "==============================================================="
echo ""
echo -n "Checking all vouchees of target account now... (about 1 minute)"
rm -f vouchees0_universe_$EPOCH2.txt
rm -f vouchees_universe_$EPOCH2.txt
rm -f my_vouchees0_$EPOCH2.txt
while IFS= read -r key; do
  libra query resource --resource-path-string 0x1::vouch::MyVouches $key | jq -r --arg key "$key" '.epoch_vouched as $epochs | .my_buddies as $buddies | [$epochs, $buddies] | transpose | map(.[1] | gsub("^0x"; "") | . as $orig | "0000000000000000000000000000000000000000000000000000000000000000\($orig)" | .[-64:] + " " + $key) | .[]' >> vouchees0_universe_$EPOCH2.txt
  sleep 2
done < raw_val_universe.txt
awk '{key=$2; gsub(/^0x/, "", key); formatted_key = sprintf("%064s", key); gsub(" ", "0", formatted_key); $2 = formatted_key; print}' vouchees0_universe_$EPOCH2.txt >> vouchees_universe_$EPOCH2.txt
awk -v accountinput="$accountinput" '$1 == accountinput' vouchees_universe_$EPOCH2.txt > my_vouchees_$EPOCH2.txt
# Define the file names
vouchers_file="my_vouchers_$EPOCH2.txt"
vouchees_file="my_vouchees_$EPOCH2.txt"
output_file="combined_$EPOCH2.txt"
rm -f combined_$EPOCH2.txt
> "$output_file"
declare -A vouchees
while IFS=' ' read -r col1 col2; do
    vouchees["$col2"]="$col1"
done < "$vouchees_file"
declare -A matched_keys
while IFS=' ' read -r col1 col2; do
    if [[ -n "${vouchees[$col1]}" ]]; then
        echo "$col1 $col2 $col1" >> "$output_file"
        matched_keys["$col1"]=1
    else
        echo "$col1 $col2" >> "$output_file"
    fi
done < "$vouchers_file"
while IFS=' ' read -r col1 col2; do
    if [[ -z "${matched_keys[$col2]}" ]]; then
        echo -e "\033[66G$col1 $col2" >> "$output_file"
    fi
done < "$vouchees_file"
echo -ne "\r"
echo -n "                                            "
sleep 0.5
echo -ne "\r"
vouchee_count=$(cat my_vouchees_$EPOCH2.txt | wc -l)
echo -e "\e[1m\e[32mVouchees from Target Account\e[0m (Target --> To) Total \e[1m\e[32m$vouchee_count\e[0m accounts"
echo "==============================================================="
cat "my_vouchees_$EPOCH2.txt"
echo "==============================================================="
echo ""
echo -e "\e[1m\e[32mVouch From-To Table for Target Account\e[0m (From --> Target --> To)"
echo "==============================================================="
cat "combined_$EPOCH2.txt"
echo "==============================================================="
echo ""
rm -f raw_val_universe.txt
rm -f vouchees0_universe_$EPOCH2.txt
echo "Done!"
echo ""