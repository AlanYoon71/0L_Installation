#!/bin/bash

while true; do
    echo ""
    echo "Input target validator account.(64-digit)"
    read -p "Target account : " targetinput
    echo ""
    echo "Input your validator account.(64-digit)"
    read -p "Your   account : " accountinput
    echo ""
    if [[ $accountinput =~ ^[A-Z0-9]{1,31}$ ]]; then
        echo "Input 64-digit full account address exactly, please."
    else
        export accountinput=$(echo $accountinput | tr 'A-Z' 'a-z')
        export targetinput=$(echo $targetinput | tr 'A-Z' 'a-z')
        echo "Target account is $targetinput"
        echo "Your   account is $accountinput."
        echo ""
        echo "Did you enter it correctly?(y/n)"
        read -p "y/n : " user_input
        if [[ $user_input == "y" ]]; then
            echo ""
            break
        fi
    fi
done

search_string="${accountinput: -6}"
target_vouch_count=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq '.my_buddies | map(select(startswith("0x"))) | length')
result=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account "$targetinput" | jq -r '.my_buddies[] | .[-6:]')
echo "$result" > target_vouches.txt
result2=$(libra query resource --resource-path-string 0x1::stake::ValidatorSet --account 0x1 | jq -r '.active_validators[].addr | .[-6:]')
echo "$result2" > active_check_for_vouch_check.txt
libra query resource --resource-path-string 0x1::stake::ValidatorSet --account 0x1 | jq -r '.active_validators[].addr' | tr ' ' '\n' > active.txt
target_file="target_vouches.txt"
check_file="active_check_for_vouch_check.txt"
count=0
rm -f print.txt &> /dev/null;
while IFS= read -r key; do
    if grep -q "$key" "$target_file"; then
        count=$((count + 1))
        echo "$key" >> print.txt
    fi
done < "$check_file"
print2=$(cat print.txt)
if [[ -z "$print2" ]]
then
    echo ""
    echo "Target account has no active vouch."
else
    print_file="print.txt"
    active_file="active.txt"
    while IFS= read -r key; do
        grep "$key" "$active_file"
    done < "$print_file"
        echo ""
        echo -e "Target account has \e[1m\e[32m$count\e[0m active vouches."
fi

match_found=false
while IFS= read -r key; do
    if [[ $key == $search_string ]]; then
        match_found=true
        break
    fi
done <<< "$result"

if [ "$match_found" = true ]; then
    echo ""
    echo "Target account has total $target_vouch_count vouchers, including yours."
    echo "Do you want to revoke your vouch for target account?(y/n)"
    read -p "y/n : " user_input
    if [[ $user_input == "y" ]]; then
        echo ""
        libra txs validator vouch --vouch-for $targetinput --revoke
        echo ""
        target_vouch_count=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq '.my_buddies | map(select(startswith("0x"))) | length')
        result=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account "$targetinput" | jq -r '.my_buddies[] | .[-6:]')
        match_found=false
        while IFS= read -r key; do
            if [[ $key == $search_string ]]; then
                match_found=true
                break
            fi
        done <<< "$result"
        if [ "$match_found" = true ]; then
            echo "It looks like revoke failed. The target account has total $target_vouch_count vouchers, including yours yet."
            libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq
        else
            echo "Your vouch has been revoked successfully. The target account has total $target_vouch_count vouchers now."
            libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq
        fi
    elif [[ $user_input == "n" ]]; then
        echo ""
    else
        echo ""
        echo "Invalid input. Please enter 'y' or 'n'."
        exit
    fi
else
    echo ""
    echo "The target account has total $target_vouch_count vouchers, but does not include yours."
    echo "Do you want to vouch for target account?(y/n)"
    read -p "y/n : " user_input
    if [[ $user_input == "y" ]]; then
        echo ""
        libra txs validator vouch --vouch-for $targetinput
        echo ""
        target_vouch_count=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq '.my_buddies | map(select(startswith("0x"))) | length')
        result=$(libra query resource --resource-path-string 0x1::vouch::MyVouches --account "$targetinput" | jq -r '.my_buddies[] | .[-6:]')
        match_found=false
        while IFS= read -r key; do
            if [[ $key == $search_string ]]; then
                match_found=true
                break
            fi
        done <<< "$result"
        if [ "$match_found" = true ]; then
            echo ""
            echo "You vouched for the target account successfully. The target account has total $target_vouch_count vouchers, including yours now."
            libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq
        else
            echo ""
            echo "Vouch failed. The target account has total $target_vouch_count vouchers, but does not include yours yet."
            libra query resource --resource-path-string 0x1::vouch::MyVouches --account $targetinput | jq
        fi
    elif [[ $user_input == "n" ]]; then
        echo ""
    else
        echo ""
        echo "Invalid input. Please enter 'y' or 'n'."
        exit
    fi
fi
echo "Done!"