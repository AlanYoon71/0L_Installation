# For beginners who want to install 0L node and experience a crownless emperor 0L network

# Installation Script

  0. You should familiarize yourself with the 0L official guide documentation before using this script.
    
     This script is intended to provide convenience only for those who have used the official guide to install a node and understand the process.
     Please read the official guide documentation first.

  1. Validator(fullnode) with tower
  
    1) Install script command

       cd ~ && git clone https://github.com/shyoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh
       (Open terminal input upper one line command at root home directory, and check TMUX sessions in another terminal)

    2) Restart script command (you can just download the restart script from here and run it by user "node")

       ~/0l_restart.sh >> $HOME/.0L/logs/restart.log 2>&1
       (Open terminal, change user to "node" and input upper command at home directory under TMUX session)

       >> Dependencies : bc, daemontools (you can install these package by "apt install -y bc daemontools")

    3) Concept

      a. Install script
        1. Faithfully followed official installation documentation.
        2. Validator and fullnode all can be installed and run by selecting onboard method.
        3. Create TMUX background sessions for installation and run all processes for running tower in TMUX sessions.
        4. Create log sessions for validator(fullnode), tower and restart script.
        5. Calculate TPS(sync transaction per second) between network and local after starting validator(fullnode),
           display remained catchup complete time(estimated).
        6. Mnemonic and answers for question should be input by user twice manually to prove not malicious bot or script.
    
      b. Restart script
        1. Check network block height by curl command(curl 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"target\"})
           at 20 and 50 minutes on the hour, restart validator and tower at every hour on the hour if block height not increases.
        2. Restart command in restart script as below.
          - Validator: ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1
          - Tower: ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1
        3. If validator was already stopped before running the restart script, this script will automatically restart it.
        4. Script can wipe local DB, restore it from network and restart validator if fails to restart due to a DB crash or other reasons.
           (Killing a running process can sometimes cause DB crash, so if the validator can't be restarted, restore operation is inevitable)
        5. If DB is restored once, script start to monitor synced height so that you can check catchup status and remained catchup time(estimated).
        6. If validator is not fully synced, it will restart in fullnode mode, and if fully synced at checkpoint, it will restart in validator mode.