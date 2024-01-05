0l Validator monitoring script for discord

1. Prepare your own discord server and channel for monitoring.
2. Make discord bot and connect bot to your discord channel.
3. Download script from your validator and edit permission script file.
   
   ```chmod +x 0l_vn_monitor_discord.sh```
5. Copy your webhook url of bot and paste url into line 25 of script.
6. Open tmux and run node.

   ```tmux new -s node```
   
   ```libra node```
8. Open tmux and run the script from validator and check if your discord channel receives messages.
   
   ```./0l_vn_monitor_discord.sh```
9. If script works well, you can see the messages like below.
   
   ```+ ======= [ VALIDATOR ] ======== +   7 validators in set.   --- [ 1-03:47:31]```
   
   ```Proposal : +175 > 29126  Synced version : +2518 > 7243686  Block height : +1253 > 3596306```
