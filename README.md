# For beginners who want to install 0L node and experience a crownless emperor 0L network

# Installation script

0. You should familiarize yourself with 0L official guide documentation before using this script.
   https://github.com/0LNetworkCommunity/libra/blob/main/ol/documentation/node-ops/validators/validator_onboarding_hard_mode.md

   This script is intended to provide convenience only for those
   who have used fficial guide to install a node and understand the process.
   Please read the official guide documentation first.
   This script was created and checked on ubuntu 20.04 LTS only.
1. Install script command

   `cd ~ && rm -rf 0L_Installation; git clone https://github.com/AlanYoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh`

   Open terminal input upper one line command at root home directory as root user,
   and check TMUX sessions in another terminal.
2. Concept

   - Faithfully followed official installation documentation.
   - Validator and fullnode all can be installed and run
     by selecting onboard method.
   - Creates TMUX background sessions for installation and
     run all processes for running tower in TMUX sessions.
   - Creates log sessions for validator(fullnode),
     tower and restart script.
   - Calculates TPS(sync transaction per second) between network
     and local after starting validator(fullnode),
     display remained catchup complete time(estimated).
   - Checks not only tower connection but also mining progress and
     shows the number of final proofs successfully submitted to the chain.
   - Mnemonic and answers for question should be input by user twice
     manually to prove not malicious bot or script.

# Monitoring(discord) and restart script for validator

1. Prepare discord bot env.
   - Make discord bot and connect bot to the channel in your own server.
   - You must copy webhook_url and save it aside.
     https://www.upwork.com/resources/how-to-make-discord-bot
2. Check your validator running env. and change it as below. 
   - You must run validator and tower as node user. (Not root)
   - You must run validator in tmux session name as validator.
   - You must run tower in tmux session name as tower.
   - If you need to change it, restart validator and tower
     as upper condition. (`tmux new -s validator`, `tmux new -s tower`)
3. Prepare script env. as `root`.
   - Download script in `/home/node/.0L/logs` (Don’t change path)
   - Change permission. (`chmod +x 0l_val_alert_bot6.sh`)
   - Edit webhook_url in the script with your own webhook_url. (line 18)
4. Check the script location and run it.
   - Change user to `root`.
   - Move to `/home/node/.0L/logs`
   - Open tmux bot session. (`tmux new -s bot`)
   - Run the script. (`./0l_val_alert_bot6.sh`) 
5. Restart/restore condition and others.
   - Basic info will be sent to your own channel with 10min interval.
   - If validator stops syncing or voting, it will be restarted.
   - If there's no new block and you are not in the final round,
     validator will be restarted.
   - If script can't fetch out sync+round+vote info,
     it will run ol restore and catch up.
   - If memory usage increase to 85%(when no new block and voting crawls),
     the script will run ol restore regen your DB.
   - Metrics port locking is default.
     If there’s no new block and syncing stops, it will be opened for cross-check.
   - If the validator exits the active set during script running,
     it is automatically recognized as full node mode and does not restart even if the voting stops.
   - If the 0lexplorer dashboard tab is not updated in real time,
     the restart function may not work even if the validator stops syncing.
