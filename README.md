## Prerequisites

Ensure you have an Ubuntu system (tested on Ubuntu 22.04) and basic familiarity with the terminal.

## Step 1: Running the Libra Validator and VFN

1. Firewall setting for Mainnet Validator

```bash
sudo ufw allow 6180; sudo ufw allow 6181; sudo ufw allow 3000; 
```

2. Firewall setting for Mainnet VFN (A machine other than the one where the Validator is installed)

```bash
sudo ufw allow 6180; sudo ufw allow 6182; sudo ufw allow 8080; 
```
	
3. Download and Run the Mainnet Setup Script

```bash
apt update && apt install nano && apt install wget
wget -O ~/0l_mainnet_setup.sh https://github.com/AlanYoon71/OpenLibra_Mainnet/raw/main/0l_mainnet_setup.sh \
&& chmod +x ~/0l_mainnet_setup.sh && ./0l_mainnet_setup.sh
```

4. Running the Libra Validator (VFN)

```bash
apt update && apt install tmux -y
tmux new -s node
libra node
```

If you want to detach from the tmux session you created, press Ctrl+b and then d.
To attach to that session again, run `tmux attach -t node`.

## Step 2: Check Syncing and Voting status

```bash
echo ""; curl -s localhost:9101/metrics | grep diem_state_sync_version{; \
echo -e "\nVote Progress:"; cat ~/.libra/data/secure-data.json | jq .safety_data.value.last_voted_round
```

If the sync and vote counts keep increasing, your node is running successfully.

To monitor the node status more deeply in real-time, I recommend installing Prometheus + Grafana.
There are already easy and excellent installation tutorials available, so refer to them.
https://airy-antimatter-608.notion.site/0L-Network-testnet-6-Self-Hosted-Prometheus-Grafana-bb45a49c14344674a7fc98d1f8c5950e
If you have already installed Prometheus and Grafana on your Validator, don't forget to open port 3000.
   
Note: 
If you are participating in the Mainnet as a first-time post-genesis Validator, 
don't forget to check the onboarding process and register using `libra txs validator register`.

Carpe Diem, Carpe Libra!✊🔆
