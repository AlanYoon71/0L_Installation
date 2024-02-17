Validator install script

1. This script is recommended for experienced users

   who have read the official doc and installed the node multiple times.

   `cd ~ && rm -rf Open_Libra_Project`

   `wget https://raw.githubusercontent.com/AlanYoon71/Open_Libra_Project/main/libra_vn_install_script.sh`

   `chmod +x libra_vn_install_script.sh && ./libra_vn_install_script.sh`


Validator-fullnode converting and monitoring script for discord

1. Prepare your own discord server and channel for monitoring (10 minutes interval).
2. Make discord bot and connect bot to your discord channel.
3. Download this script from your validator and edit permission script file.

   `chmod +x vn_fn_converter_discord.sh`
4. Copy your webhook url of bot and paste url into line 37 of script.
5. Open tmux and run node. Don't change the tmux session name `node`.

   `tmux new -s node`

   `libra node`
6. Open tmux and run the script from validator and check if your discord channel receives messages.

   `tmux new -s bot`

   `./vn_fn_converter_discord.sh`
7. If script works well, you can see the messages like below in your personal server.

   `Script starts.`

   `+ ======= [ VALIDATOR ] ======== +  15 nodes in set are active now.`

   `Proposal : +175 > 29126  Synced version : +2518 > 7243686  Block height : +1253 > 3596306`
