# For beginners who want to install 0l node and experience an uncrowned king 0L network

# Installation Script :

  1. Validator(fullnode) with tower
  
    1) one-line commands
        cd ~ && git clone https://github.com/shyoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh
        (Open terminal input upper one line command at root home directory, and check TMUX sessions in another terminal)

    2) Concept

      a. Installation script
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
        2. Monitor the local synced height so that you can check catchup stability(lagging) and remained catchup time(estimated).
        3. Restart command in restart script as below.
          - Validator: ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 &
          - Tower: ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1 &
        4. If validator was already stopped before running the restart script, the above command will automatically restart it.