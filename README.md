# For beginners who want to install 0L node and experience a crownless emperor 0L network

# Installation Script

0. You should familiarize yourself with 0L official guide documentation before using this script.
   https://github.com/0LNetworkCommunity/libra/blob/main/ol/documentation/node-ops/validators/validator_onboarding_hard_mode.md

   This script is intended to provide convenience only for those
   who have used fficial guide to install a node and understand the process.
   Please read the official guide documentation first.
   This script was created and checked on ubuntu 20.04 LTS only.
2. Validator(fullnode) and tower

   1) Install script command

   cd ~ && git clone https://github.com/AlanYoon71/0L_Installation.git && \cp -f 0L_Installation/* ./ && chmod +x *sh && bash ./0l_env_val.sh

   Open terminal input upper one line command at root home directory as root user,
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
