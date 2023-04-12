# For beginners who want to install 0L node and experience a crownless emperor 0L network

# Installation Script

  0. You should familiarize yourself with 0L official guide documentation before using this script.
     https://github.com/0LNetworkCommunity/libra/blob/main/ol/documentation/node-ops/validators/validator_onboarding_hard_mode.md
    
     This script is intended to provide convenience only for those 
     who have used fficial guide to install a node and understand the process.
     Please read the official guide documentation first. 
     This script was created and checked on ubuntu 20.04 LTS only.

  1. Validator(fullnode) and tower
  
    1) Install script command

     cd ~ && git clone https://github.com/AlanYoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh
     Open terminal input upper one line command at root home directory,
     and check TMUX sessions in another terminal

    2) Concept

     1. Faithfully followed official installation documentation.
     2. Validator and fullnode all can be installed and run
        by selecting onboard method.
     3. Creates TMUX background sessions for installation and 
        run all processes for running tower in TMUX sessions.
     4. Creates log sessions for validator(fullnode),
        tower and restart script.
     5. Calculates TPS(sync transaction per second) between network
        and local after starting validator(fullnode),
        display remained catchup complete time(estimated).
     6. Checks not only tower connection but also mining progress and
        shows the number of final proofs successfully submitted to the chain.
     7. Mnemonic and answers for question should be input by user twice
        manually to prove not malicious bot or script.

  2. CLI monitoring tool(Restart script)

    1) Restart script command (you can just download and run it by user "node")

     Download 0l_restart.sh and 0l_non-voting_address.sh at /home/node/.0L/logs directory.
     Change permission(chmod +x) and run it(./0l_restart.sh) under TMUX session.
     You need input your validator account to make sure votes is in progress when
     consensus round stopped by scanning "broadcast to all peers" log.

     >> Notice
     - If you are not in the active validator set, do not use this script.
     - This script need package dependencies "bc" for calculating TPS,
       you can install with "apt install bc" by root user.

    2) Concept
    
     1. Checks consensus current round, local and network block height
        by curl command at **:20 and **:50 minutes, 
        restart validator and tower at every hour on the hour if round and
        local block height not increases at the same time.
     2. If block height increases and the local height or round does not increase,
        restart immediately at sync lag 1000.(scan interval : 20s)
     3. Restarts command in restart script as below.
        - Validator: nohup ~/bin/diem-node --config ~/.0L/validator.node.yaml 2>&1 | multilog s104857600 n10 ~/.0L/logs/node &
        - Tower: ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1
     4. If validator was already stopped before running the restart script,
        this script will automatically restart it.
     5. Script can wipe local DB, restore it from 0l network repo and 
        restart validator if fails to restart due to a DB crash or other reasons.
        Killing a running process can sometimes cause DB crash, so 
        if the validator can't be restarted, restore operation is inevitable.
     6. If DB is restored once, script start to monitor synced height so that
        you can check catchup status.
     7. Monitors TPS between network and local and restarts validator
        if local speed drops significantly to prevent syncing stop.
     8. If your validator is inactive and in non-voting status, 
        this script will restart your node.(check pooint time : **:58)