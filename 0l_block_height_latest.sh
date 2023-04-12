#!/bin/bash

#!/bin/bash

# Get the JSON data from the website
json_data=$(curl -s https://0lexplorer.io/)

# Extract the version number using jq
version_number=$(echo "$json_data" | jq '.version')

# Print the version number
echo "Version: $version_number"