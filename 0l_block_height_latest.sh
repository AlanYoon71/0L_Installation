#!/bin/bash

# Get the HTML data from the website
html_data=$(curl -s https://0lexplorer.io/)

# Extract the first version number using grep and awk
version_number=$(echo "$html_data" | grep -oPm1 '(?<=version":)[^"]*' | awk -F ',' 'NR==1{print $1; exit}')

# Print the first version number
echo "The latest version: $version_number"