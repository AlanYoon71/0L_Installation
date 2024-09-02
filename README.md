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

4. Running the Libra Validator

```bash
apt update && apt install tmux -y
tmux new -s node
libra node
```

5. Running the Libra VFN (if you setup manually)

```bash
#open port 6181 at VN
sudo ufw allow 6181

#copy full_node_network_public_key in the public-keys.yaml at VN
grep full_node_network_public_key ~/.libra/public-keys.yaml

#modify ~/.libra/operator.yaml by inserting full_node_network_public_key and port 6182 at VN
#modify ~/.libra/vfn.yaml by inserting VN_IP
#update validator config on chain at VN
libra txs validator update

#make a zip file for validator config files at VN
cd && tar -cvf vn_config.zip --exclude=.libra/data .libra

#build binaries at VFN
cd && apt update && apt install -y sudo nano wget git tmux \
&& git clone https://github.com/0LNetworkCommunity/libra-framework \
&& cd ~/libra-framework && yes | bash ./util/dev_setup.sh -t \
&& . ~/.bashrc && cargo build --release -p libra \
&& cp -f ~/libra-framework/target/release/libra* ~/.cargo/bin/ \
&& libra version

#transfer a zip file to VFN at VN
cd && scp vn_config.zip <username>@<VFN_IP>:/home/<username>/

#decompress a zip file at VFN
cd && tar -xvf vn_config.zip

#open tmux session and start VFN and check syncing status
libra node --config-path ~/.libra/vfn.yaml

#check vfn network connection at VN
curl -s localhost:9101/metrics | grep connections{

#open port 6182 at VFN
sudo ufw allow 6182
```

A VFN is like the shadow of a validator. If you face a difficult situation where you cannot continue running the validator, the quickest way to recover the validator is to run the VFN as a validator. Simply modify the validator IP address in the `operator.yaml` file, update the validator config using the `libra txs validator update` command, and then start the validator using the `libra node` command.

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
