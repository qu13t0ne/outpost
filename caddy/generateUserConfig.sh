#!/bin/bash
#########################################################
#  GENERATE USER CONFIG FOR CADDY-SECURITY LOCAL AUTH
#  
#        Written by: Mike Owens
#        Email:      mikeowens (at) fastmail (dot) com
#        Website:    https://michaelowens.me
#        GitLab:     https://gitlab.com/mikeo85
#        GitHub:     https://github.com/mikeo85
#        Twitter:    https://twitter.com/quietmike8192
#
#  This script will output the necessary JSON to add a
#  new user to the Caddy-Security users.json file. It
#  does not actually update users.json, but it does
#  simplify the process of creating the required configs
#  with correct data and timestamps. 
#
#########################################################

# ===== FUNCTIONS =====================

checkPackages() {
	which $1 > /dev/null
	status=$?
	if [ $status -ne 0 ];then
		printf "Error: Package \'$1\' is required and not installed. Please install it and rerun the script.\n"
		exit 2
	# else
		# printf "... Required package \'$1\' is installed. Continuing.\n"
	fi
}

promptUserConfirmation() {
	while true; do
    read -p "Continue (y/n)? " choice
    case "$choice" in 
      y|Y ) echo "Continuing..." && break;;
      n|N ) echo "Terminating..." && exit;;
      * ) echo "Invalid entry. Try again...";;
    esac
	done
}

# ===== SCRIPT ========================

# Check for required packages
checkPackages uuidgen

# Capture Info
read -p "Enter USERNAME (no spaces): " username
read -p "Enter EMAIL: " email
printf "Generate a bcrypt password hash using cost=10 and enter the hash below.\n"
printf "    Note: Site https://bcrypt.online can be used to generate.\n"
read -p "Bcrypt Hash: " pwhash

# Generate UUID
uuid=$(uuidgen)

# Generate Timestamp
timestamp=$(date -u +"%FT%T.%NZ")

# Generate JSON for User
printf "\n\n# USER CONFIGURATION GENERATED
    Insert the following JSON into the appropriate section of the users.json file.
	Copy all lines between (but not including) the BEGIN and END tags.\n\n"
printf "[---BEGIN JSON---]\n"
printf '    {
      "id": "%s",
      "username": "%s",
      "email_address": {
        "address": "%s",
        "domain": "localdomain.local"
      },
      "email_addresses": [
        {
          "address": "%s",
          "domain": "localdomain.local"
        }
      ],
      "passwords": [
        {
          "purpose": "generic",
          "algorithm": "bcrypt",
          "hash": "%s",
          "cost": 10,
          "expired_at": "0001-01-01T00:00:00Z",
          "created_at": "%s",
          "disabled_at": "0001-01-01T00:00:00Z"
        }
      ],
      "created": "%s",
      "last_modified": "%s",
      "revision": 1,
      "roles": [
        {
          "name": "user",
          "organization": "authp"
        }
      ]
    }\n' "$uuid" "$username" "$email" "$email" "$pwhash" "$timestamp" $timestamp $timestamp
printf "[---END JSON---]\n"
printf "[end of script]\n"