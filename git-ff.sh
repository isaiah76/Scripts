#!/bin/bash

echo -n "Enter your GitHub Token: "
read -s GITHUB_TOKEN
echo ""

echo -n "Enter your GitHub username: "
read GITHUB_USERNAME

# Function to fetch paginated results
fetch_paginated_data() {
    local endpoint=$1
    local page=1
    local results=""

    while :; do
        data=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/users/$GITHUB_USERNAME/$endpoint?per_page=100&page=$page" | jq -r '.[].login')
        
        [[ -z "$data" ]] && break
        
        results+="$data"$'\n'

        ((page++))
    done

    echo "$results"
}

FOLLOWING=$(fetch_paginated_data "following")
FOLLOWERS=$(fetch_paginated_data "followers")

echo "Users you follow who don't follow you back:"
comm -23 <(echo "$FOLLOWING" | sort) <(echo "$FOLLOWERS" | sort)

