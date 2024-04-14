Validator install script `(0l_vn_setup.sh)`

1. This script is recommended for experienced users

   who have read the official doc and installed the node multiple times.

   `cd ~ && wget -O ~/0l_vn_setup.sh https://raw.githubusercontent.com/AlanYoon71/0L_Network/main/0l_vn_setup.sh`

   `chmod +x 0l_vn_setup.sh && ./0l_vn_setup.sh`

Validator monitoring script for discord `(validator_monitor.sh)`

1. Prepare your own discord server and channel for monitoring (10 minutes interval).
2. Make discord bot and connect bot to your discord channel.
3. Download this script from your validator and edit permission script file.

   `chmod +x validator_monitor.sh`
4. Copy your webhook url of bot and paste url into line 17 of script.
5. Open tmux and run node. Don't change the tmux session name `node`.

   `tmux new -s node`

   `libra node`
6. Open tmux and run the script from validator and check if your discord channel receives messages.

   `tmux new -s bot`

   `./validator_monitor.sh`
7. If script works well, you can see the messages like below in your personal server.

   `Script starts.`

   `+ ======= [ VALIDATOR ] ======== +  15 nodes in set are active.`

   `Proposal : +175 > 29126  Synced : +2518 > 7243686  Block : +1253 > 3596306`
