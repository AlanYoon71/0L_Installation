#!/bin/bash

sudo apt install -y expect > /dev/null;
echo ""
read -p "Enter your validator account key (Include 0x): " key

EPOCH=$(curl -s http://localhost:8080/v1/ | jq -r '.epoch')

if [ -z "$EPOCH" ]; then
  echo "Failed to retrieve current epoch."
  exit 1
fi

check_target_epoch=$((EPOCH - 45 -1))
echo "Enter the expiration period value of current vouch system. If you input 45, your given-vouches will be revoked from epoch $check_target_epoch to epoch 0."
read -p "Expiration period (ex.45): " epoch_expired
confirmed_target_epoch=$((EPOCH - epoch_expired -1))

echo ""
echo "Your vouches will be revoked from epoch $confirmed_target_epoch to epoch 0. Confirmed."
sleep 3
echo ""

response=$(libra query resource --resource-path-string 0x1::vouch::GivenVouches "$key" | jq)
if [ -z "$response" ]; then
  echo "Failed to retrieve data."
  exit 1
fi

epoch_vouched=($(echo "$response" | jq -r '.epoch_vouched[]'))
outgoing_vouches=($(echo "$response" | jq -r '.outgoing_vouches[]'))

target_addresses=()

for i in "${!epoch_vouched[@]}"; do
  if [ "${epoch_vouched[$i]}" -le "$confirmed_target_epoch" ]; then
    target_addresses+=("${outgoing_vouches[$i]}")
  fi
done

for target in "${target_addresses[@]}"; do
  echo "Revoking vouch for $target..."

  echo "Input your mnemonic for multiple revoke transaction."
  read -sp "Mnemonic: " MNEMONIC1
  echo ""

  expect <<EOF
  spawn libra txs validator vouch --vouch-for "$target" --revoke
  expect "mnemonic:"
  send "$MNEMONIC1\r"
  sleep 3
  echo ""
  expect eof
EOF

done

echo "Revoke process completed."

