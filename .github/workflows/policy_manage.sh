#!/bin/bash

json_data=$1
CHEFADMIN=$2
TESTUSER=$3
# Output directory location
output_dir="$HOME/.chef"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"
failed_org_log="failed_org_log_${date +%Y%m%d_%H%M%S}.txt"

# Creating the pem file
echo "$CHEFADMIN" > $HOME/.chef/chefadmin.pem
echo "$TESTUSER" > $HOME/.chef/testuser.pem
# Parse JSON and extract values into variables in a loop
echo "$json_data" | jq -r 'to_entries[] | "\(.key) \(.value.client_name) \(.value.client_key_name) \(.value.org_name)"' | while read -r org client_name client_key_name org_name; do
  # Create the configuration file
  config_file="$output_dir/credentials"
  client_key_name_small=$(echo $client_key_name | tr '[:upper:]' '[:lower:]')
  echo "[default]" > "$config_file"
  echo "client_name     = \"$client_name\"" >> "$config_file"
  echo "client_key      = '$HOME/.chef/$client_key_name_small.pem'" >> "$config_file"
  echo "chef_server_url = 'https://ec2-13-233-133-198.ap-south-1.compute.amazonaws.com/organizations/$org_name'" >> "$config_file"
  
  cat $config_file
  
  knife ssl fetch 
  knife ssl check
  knife client list
  if [ $? != 0 ]; then
    echo "knife connectivity is failed for org $org_name"
    echo "knife connectivity is failed for org $org_name" >> "$failed_org_log"
  fi
  # chef install Policyfile.rb
  # chef push dev Policyfile.lock.json
done




