#!/bin/bash

# Delete all Gitea users except gitea_admin
# Requires: curl, jq
# Usage: ./delete-all-gitea-users.sh

# Configuration - modify these variables
GITEA_URL="https://gitea.training.cluster.acend.ch/"
#GITEA_TOKEN=""
ADMIN_USER="gitea_admin"

# Optional: Set to "true" to enable dry-run mode (shows what would be deleted without actually deleting)
DRY_RUN="false"

# Optional: Add additional users to preserve (space-separated)
PRESERVE_USERS="$ADMIN_USER"  # Add more like: "gitea_admin user2 user3"

if [ -z "$GITEA_URL" ] || [ "$GITEA_URL" == "https://your-gitea-server.com" ]; then
    echo "Error: Please set GITEA_URL in the script"
    exit 1
fi

if [ -z "$GITEA_TOKEN" ] || [ "$GITEA_TOKEN" == "your-api-token-here" ]; then
    echo "Error: Please set GITEA_TOKEN in the script"
    echo "You can generate a token at: $GITEA_URL/user/settings/applications"
    echo "Note: Token must have admin privileges to delete users"
    exit 1
fi

# Check if required tools are installed
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed."; exit 1; }

echo "Fetching all users from $GITEA_URL..."

# Get all users (paginated)
page=1
all_users=""

while true; do
    echo "Fetching page $page..."
    users=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/admin/users?page=$page&limit=50")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch users"
        exit 1
    fi
    
    # Check if we got any users on this page
    user_count=$(echo "$users" | jq 'length')
    if [ "$user_count" -eq 0 ]; then
        break
    fi
    
    # Add users to our collection
    if [ -z "$all_users" ]; then
        all_users="$users"
    else
        all_users=$(echo "$all_users" "$users" | jq -s 'add')
    fi
    
    ((page++))
done

total_users=$(echo "$all_users" | jq 'length')
echo "Found $total_users total users"

if [ "$total_users" -eq 0 ]; then
    echo "No users found"
    exit 0
fi

# Filter out preserved users
users_to_delete=""
preserved_users=""

for user in $(echo "$all_users" | jq -r '.[].login'); do
    should_preserve=false
    
    for preserve_user in $PRESERVE_USERS; do
        if [ "$user" == "$preserve_user" ]; then
            should_preserve=true
            preserved_users="$preserved_users $user"
            break
        fi
    done
    
    if [ "$should_preserve" == "false" ]; then
        if [ -z "$users_to_delete" ]; then
            users_to_delete="$user"
        else
            users_to_delete="$users_to_delete $user"
        fi
    fi
done

delete_count=$(echo $users_to_delete | wc -w)
preserve_count=$(echo $preserved_users | wc -w)

echo ""
echo "Users to be preserved ($preserve_count):$preserved_users"
echo ""
echo "Users to be deleted ($delete_count):"
for user in $users_to_delete; do
    user_info=$(echo "$all_users" | jq -r ".[] | select(.login == \"$user\") | \"- \(.login) (\(.full_name // \"No full name\")) - \(.email)\"")
    echo "$user_info"
done

if [ "$delete_count" -eq 0 ]; then
    echo "No users to delete"
    exit 0
fi

if [ "$DRY_RUN" == "true" ]; then
    echo ""
    echo "DRY RUN MODE - No users were actually deleted"
    exit 0
fi

echo ""
read -p "Are you sure you want to delete $delete_count users? This cannot be undone! (type 'DELETE USERS' to confirm): " confirmation

if [ "$confirmation" != "DELETE USERS" ]; then
    echo "Operation cancelled"
    exit 0
fi

echo ""
echo "Starting user deletion..."

# Delete each user
deleted_count=0
failed_count=0

for username in $users_to_delete; do
    echo "Deleting user: $username..."
    
    response=$(curl -s -w "%{http_code}" -X DELETE \
        -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/admin/users/$username?purge=true")
    
    http_code=$(echo "$response" | tail -c 4)
    
    if [ "$http_code" -eq 204 ]; then
        echo "✓ Successfully deleted user: $username"
        ((deleted_count++))
    else
        echo "✗ Failed to delete user: $username (HTTP $http_code)"
        response_body=$(echo "$response" | sed 's/...$//')
        if [ -n "$response_body" ]; then
            echo "  Response: $response_body"
        fi
        ((failed_count++))
    fi
    
    # Small delay to avoid overwhelming the server
    sleep 0.5
done

echo ""
echo "User deletion complete!"
echo "Successfully deleted: $deleted_count users"
echo "Failed to delete: $failed_count users"
echo "Preserved users:$preserved_users"