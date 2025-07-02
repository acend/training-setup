#!/bin/bash

# Delete all repositories on a Gitea server
# Requires: curl, jq
# Usage: ./delete-all-gitea-repos.sh

# Configuration - modify these variables
GITEA_URL="https://gitea.training.cluster.acend.ch/"
# GITEA_TOKEN=""

# Optional: Set to "true" to enable dry-run mode (shows what would be deleted without actually deleting)
DRY_RUN="false"

if [ -z "$GITEA_URL" ] || [ "$GITEA_URL" == "https://your-gitea-server.com" ]; then
    echo "Error: Please set GITEA_URL in the script"
    exit 1
fi

if [ -z "$GITEA_TOKEN" ] || [ "$GITEA_TOKEN" == "your-api-token-here" ]; then
    echo "Error: Please set GITEA_TOKEN in the script"
    echo "You can generate a token at: $GITEA_URL/user/settings/applications"
    exit 1
fi

# Check if required tools are installed
command -v curl >/dev/null 2>&1 || { echo "Error: curl is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed."; exit 1; }

echo "Fetching all repositories from $GITEA_URL..."

# Get all repositories (paginated)
page=1
all_repos=""

while true; do
    echo "Fetching page $page..."
    repos=$(curl -s -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/search?page=$page&limit=50")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch repositories"
        exit 1
    fi
    
    # Check if we got any repos on this page
    repo_count=$(echo "$repos" | jq '.data | length')
    if [ "$repo_count" -eq 0 ]; then
        break
    fi
    
    # Add repos to our collection
    if [ -z "$all_repos" ]; then
        all_repos=$(echo "$repos" | jq '.data')
    else
        all_repos=$(echo "$all_repos" $(echo "$repos" | jq '.data') | jq -s 'add')
    fi
    
    ((page++))
done

total_repos=$(echo "$all_repos" | jq 'length')
echo "Found $total_repos repositories"

if [ "$total_repos" -eq 0 ]; then
    echo "No repositories found"
    exit 0
fi

# Show what will be deleted
echo ""
echo "The following repositories will be deleted:"
echo "$all_repos" | jq -r '.[] | "- \(.full_name) (Owner: \(.owner.login))"'

if [ "$DRY_RUN" == "true" ]; then
    echo ""
    echo "DRY RUN MODE - No repositories were actually deleted"
    exit 0
fi

echo ""
read -p "Are you sure you want to delete ALL $total_repos repositories? This cannot be undone! (type 'DELETE ALL' to confirm): " confirmation

if [ "$confirmation" != "DELETE ALL" ]; then
    echo "Operation cancelled"
    exit 0
fi

echo ""
echo "Starting deletion..."

# Delete each repository
deleted_count=0
failed_count=0

echo "$all_repos" | jq -r '.[] | "\(.owner.login)/\(.name)"' | while read repo_full_name; do
    echo "Deleting $repo_full_name..."
    
    response=$(curl -s -w "%{http_code}" -X DELETE \
        -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$repo_full_name")
    
    http_code=$(echo "$response" | tail -c 4)
    
    if [ "$http_code" -eq 204 ]; then
        echo "✓ Successfully deleted $repo_full_name"
        ((deleted_count++))
    else
        echo "✗ Failed to delete $repo_full_name (HTTP $http_code)"
        ((failed_count++))
    fi
    
    # Small delay to avoid overwhelming the server
    sleep 0.5
done

echo ""
echo "Deletion complete!"
echo "Successfully deleted: $deleted_count repositories"
echo "Failed to delete: $failed_count repositories"