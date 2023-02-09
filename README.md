# For beginners who want to install 0l node and experience an uncrowned king 0L network

# Installation Script :

  1. Validator(fullnode) with tower
  
    1) Command
      - cd ~ && git clone https://github.com/shyoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh
      - start script by root directory.

    2) Concept:
      - This script Faithfully followed official installation documentation.
      - Validator and fullnode all can be installed and run by selecting onboard method. 
      - Create TMUX background sessions for installation and run all processes for running tower in TMUX sessions.
      - Create log sessions for validator(fullnode), tower and restart script.
      - Check network block height by curl command every 30 minutes(--:20, --:50 fixed), restart validator at every hour on the hour if block height not increases. 
      - Calculate TPS(sync transaction per second) between network and local after starting validator(fullnode), display remained catchup complete time(estimated).
      - Mnemonic and answers for question should be input by user twice manually to prove not malicious bot or script.
