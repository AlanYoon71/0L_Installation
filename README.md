# For beginners who want to install 0l node and experience an uncrowned king 0L network

# Installation Script :

  1. Validator(fullnode) with tower
  
    1) Command: cd ~ && git clone https://github.com/shyoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh
      - Open terminal input upper one line command at root home directory, and check TMUX sessions in another terminal.

    2) Concept:
      a. Installation script
        - Faithfully followed official installation documentation.
        - Validator and fullnode all can be installed and run by selecting onboard method.
        - Create TMUX background sessions for installation and run all processes for running tower in TMUX sessions.
        - Create log sessions for validator(fullnode), tower and restart script.
        - Calculate TPS(sync transaction per second) between network and local after starting validator(fullnode),
          display remained catchup complete time(estimated).
        - Mnemonic and answers for question should be input by user twice manually to prove not malicious bot or script.
      b. Restart script
        - Check network block height by curl command every 30 minutes(--:20, --:50 fixed),
          restart validator and tower at every hour on the hour if block height not increases.
        - Restart command in restart script as below.
          Validator: ~/bin/diem-node --config ~/.0L/validator.node.yaml >> ~/.0L/logs/validator.log 2>&1 &
          Tower: ~/bin/tower -o start >> ~/.0L/logs/tower.log 2>&1 &