#!/bin/bash

json_data=$1
CHEFADMIN=$2
TESTUSER=$3
# Output directory location
output_dir="$HOME/.chef"
COUNTER=1
failed_org=()

# Create output directory if it doesn't exist
mkdir -p "$output_dir"
d=$(date +%Y%m%d_%H%M%S)
touch $d

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
  
  sudo ls -lhrt $HOME/.chef
  knife ssl fetch 
  echo $?
  knife ssl check
  echo $?
  knife client list
  if [ $? != 0 ]; then
    echo "knife connectivity is failed for org $org_name"
    failed_org+=("$org_name")
    echo "${failed_org[*]}"
  fi
  echo " $COUNTER "
  COUNTER=$[$COUNTER +1]
done

# Print the array of failed Organizations
echo "Failed orgs: ${failed_org[*]}"
if [ ${#failed_org[@]} > 0 ]; then
    echo "${failed_org[@]}"
    echo "$failed_org"
fi

cat $d



