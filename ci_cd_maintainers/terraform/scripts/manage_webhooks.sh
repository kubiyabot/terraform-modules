#!/bin/bash
# Script to manage GitHub webhooks in batches
# This script can efficiently create webhooks for 200-250 repositories

# Usage: ./manage_webhooks.sh <github_token> <webhook_url> <events> <repos_file> <action>
# action: create or delete

set -e

GITHUB_TOKEN="$1"
WEBHOOK_URL="$2"
EVENTS="$3"
REPOS_FILE="$4"
ACTION="$5"

# Rate limit settings
MAX_CONCURRENT=10
RATE_LIMIT_DELAY=0.5

# Create a temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/webhook_operations.log"
VALIDATION_LOG="$TEMP_DIR/validation.log"

echo "Starting webhook script at $(date)" > "$LOG_FILE"

# Validate GitHub token and repository access
validate_token_and_repos() {
  echo "Validating GitHub token and repository access..." > "$VALIDATION_LOG"
  
  # Validate GitHub token
  echo "Checking GitHub token validity..." >> "$VALIDATION_LOG"
  USER_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user")
  
  if echo "$USER_RESPONSE" | grep -q "Bad credentials"; then
    echo "ERROR: Invalid GitHub token. Authentication failed." | tee -a "$VALIDATION_LOG" "$LOG_FILE"
    return 1
  fi
  
  USERNAME=$(echo "$USER_RESPONSE" | jq -r '.login')
  if [ "$USERNAME" == "null" ] || [ -z "$USERNAME" ]; then
    echo "ERROR: Unable to retrieve user information. Token may be invalid." | tee -a "$VALIDATION_LOG" "$LOG_FILE"
    return 1
  fi
  
  echo "Token validated successfully for user: $USERNAME" >> "$VALIDATION_LOG"
  
  # Validate access to each repository
  echo "Checking repository access..." >> "$VALIDATION_LOG"
  local REPO_COUNT=0
  local FAILURE_COUNT=0
  local FAILED_REPOS=""
  
  while read REPO; do
    # Skip empty lines
    [[ -z "$REPO" ]] && continue
    
    REPO_COUNT=$((REPO_COUNT+1))
    OWNER=$(echo $REPO | cut -d'/' -f1)
    REPO_NAME=$(echo $REPO | cut -d'/' -f2)
    
    # Check if we can access the repository
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$OWNER/$REPO_NAME")
    
    if [[ "$HTTP_CODE" -ne 200 ]]; then
      echo "WARNING: Cannot access repository $OWNER/$REPO_NAME (HTTP $HTTP_CODE)" >> "$VALIDATION_LOG"
      FAILURE_COUNT=$((FAILURE_COUNT+1))
      FAILED_REPOS="$FAILED_REPOS\n  - $OWNER/$REPO_NAME (HTTP $HTTP_CODE)"
    else
      # Check if we have admin rights (needed for webhook management)
      PERMISSIONS=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$OWNER/$REPO_NAME" | jq -r '.permissions')
      
      HAS_ADMIN=$(echo "$PERMISSIONS" | jq -r '.admin')
      if [[ "$HAS_ADMIN" != "true" ]]; then
        echo "WARNING: No admin rights for repository $OWNER/$REPO_NAME" >> "$VALIDATION_LOG"
        FAILURE_COUNT=$((FAILURE_COUNT+1))
        FAILED_REPOS="$FAILED_REPOS\n  - $OWNER/$REPO_NAME (No admin rights)"
      fi
    fi
    
    # Simple progress indicator
    if [[ $((REPO_COUNT % 10)) -eq 0 ]]; then
      echo "Validated $REPO_COUNT repositories so far..." >> "$VALIDATION_LOG"
    fi
    
    # Rate limiting
    sleep 0.2
  done < "$REPOS_FILE"
  
  echo "Repository validation complete." >> "$VALIDATION_LOG"
  echo "Total repositories: $REPO_COUNT" >> "$VALIDATION_LOG"
  echo "Failed validations: $FAILURE_COUNT" >> "$VALIDATION_LOG"
  
  if [[ $FAILURE_COUNT -gt 0 ]]; then
    echo "ERROR: Validation failed for $FAILURE_COUNT out of $REPO_COUNT repositories." | tee -a "$VALIDATION_LOG" "$LOG_FILE"
    echo -e "Failed repositories:$FAILED_REPOS" | tee -a "$VALIDATION_LOG" "$LOG_FILE"
    
    # Calculate failure percentage
    FAILURE_PERCENT=$((FAILURE_COUNT * 100 / REPO_COUNT))
    if [[ $FAILURE_PERCENT -gt 10 ]]; then
      echo "ERROR: More than 10% of repositories failed validation. Aborting." | tee -a "$VALIDATION_LOG" "$LOG_FILE"
      return 1
    else
      echo "WARNING: Some repositories failed validation but continuing as failure rate is below 10%." | tee -a "$VALIDATION_LOG" "$LOG_FILE"
      return 0
    fi
  fi
  
  echo "All repositories validated successfully!" >> "$VALIDATION_LOG"
  return 0
}

# Function to create a webhook
create_webhook() {
  local REPO="$1"
  local OWNER=$(echo $REPO | cut -d'/' -f1)
  local REPO_NAME=$(echo $REPO | cut -d'/' -f2)
  local LOGFILE="$TEMP_DIR/$OWNER-$REPO_NAME.log"
  
  echo "Creating webhook for $OWNER/$REPO_NAME" >> "$LOGFILE"
  
  # Prepare events array for JSON
  local EVENTS_JSON=""
  IFS=',' read -ra EVENT_ARRAY <<< "$EVENTS"
  for EVENT in "${EVENT_ARRAY[@]}"; do
    EVENTS_JSON="$EVENTS_JSON\"$EVENT\","
  done
  EVENTS_JSON=$(echo $EVENTS_JSON | sed 's/,$//')
  
  # Create webhook via GitHub API
  HTTP_CODE=$(curl -s -o "$LOGFILE" -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks" \
    -d "{
      \"name\": \"web\",
      \"active\": true,
      \"events\": [$EVENTS_JSON],
      \"config\": {
        \"url\": \"$WEBHOOK_URL\",
        \"content_type\": \"json\",
        \"insecure_ssl\": \"0\"
      }
    }")
  
  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    echo "SUCCESS: Created webhook for $OWNER/$REPO_NAME" >> "$LOG_FILE"
  else
    echo "ERROR: Failed to create webhook for $OWNER/$REPO_NAME - HTTP $HTTP_CODE" >> "$LOG_FILE"
    cat "$LOGFILE" >> "$LOG_FILE"
  fi
}

# Function to delete a webhook
delete_webhook() {
  local REPO="$1"
  local OWNER=$(echo $REPO | cut -d'/' -f1)
  local REPO_NAME=$(echo $REPO | cut -d'/' -f2)
  local LOGFILE="$TEMP_DIR/$OWNER-$REPO_NAME.log"
  
  echo "Deleting webhooks for $OWNER/$REPO_NAME" >> "$LOGFILE"
  
  # Get all webhooks for repo
  HOOKS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks")
  
  # Find and delete webhook with matching URL
  echo "$HOOKS" | jq -c '.[]' 2>/dev/null | while read HOOK; do
    HOOK_URL=$(echo "$HOOK" | jq -r '.config.url')
    HOOK_ID=$(echo "$HOOK" | jq -r '.id')
    
    if [[ "$HOOK_URL" == "$WEBHOOK_URL" ]]; then
      HTTP_CODE=$(curl -s -o "$LOGFILE" -w "%{http_code}" \
        -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$OWNER/$REPO_NAME/hooks/$HOOK_ID")
      
      if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
        echo "SUCCESS: Deleted webhook $HOOK_ID from $OWNER/$REPO_NAME" >> "$LOG_FILE"
      else
        echo "ERROR: Failed to delete webhook $HOOK_ID from $OWNER/$REPO_NAME - HTTP $HTTP_CODE" >> "$LOG_FILE"
      fi
    fi
  done
}

# Process repositories in parallel
process_repos() {
  local ACTION="$1"
  local COUNT=0
  
  while read REPO; do
    # Skip empty lines
    [[ -z "$REPO" ]] && continue
    
    # Process in background to run in parallel
    if [[ "$ACTION" == "create" ]]; then
      create_webhook "$REPO" &
    else
      delete_webhook "$REPO" &
    fi
    
    # Increment counter and check if we need to wait
    COUNT=$((COUNT+1))
    if [[ $COUNT -eq $MAX_CONCURRENT ]]; then
      wait
      COUNT=0
      sleep $RATE_LIMIT_DELAY
    fi
  done < "$REPOS_FILE"
  
  # Wait for any remaining background jobs
  wait
}

# Verify required tools are installed
check_requirements() {
  local MISSING_TOOLS=0
  
  if ! command -v curl &> /dev/null; then
    echo "ERROR: curl is required but not installed." >> "$LOG_FILE"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  fi
  
  if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed." >> "$LOG_FILE"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  fi
  
  if [[ $MISSING_TOOLS -gt 0 ]]; then
    echo "ERROR: Missing required tools. Please install the missing tools and try again." >> "$LOG_FILE"
    return 1
  fi
  
  return 0
}

# Verify arguments
if [[ -z "$GITHUB_TOKEN" || -z "$WEBHOOK_URL" || -z "$EVENTS" || -z "$REPOS_FILE" || -z "$ACTION" ]]; then
  echo "ERROR: Missing required arguments" | tee "$LOG_FILE"
  echo "Usage: $0 <github_token> <webhook_url> <events> <repos_file> <action>" | tee -a "$LOG_FILE"
  exit 1
fi

if [[ ! -f "$REPOS_FILE" ]]; then
  echo "ERROR: Repository file does not exist: $REPOS_FILE" | tee "$LOG_FILE"
  exit 1
fi

if [[ "$ACTION" != "create" && "$ACTION" != "delete" ]]; then
  echo "ERROR: Invalid action: $ACTION. Use 'create' or 'delete'" | tee "$LOG_FILE"
  exit 1
fi

# Check requirements
if ! check_requirements; then
  cat "$LOG_FILE"
  exit 1
fi

# Validate token and repositories
if ! validate_token_and_repos; then
  cat "$LOG_FILE"
  exit 1
fi

# Main execution
if [[ "$ACTION" == "create" ]]; then
  echo "Starting webhook creation process at $(date)" >> "$LOG_FILE"
  process_repos "create"
elif [[ "$ACTION" == "delete" ]]; then
  echo "Starting webhook deletion process at $(date)" >> "$LOG_FILE"
  process_repos "delete"
fi

echo "Operation completed at $(date)" >> "$LOG_FILE"
cat "$LOG_FILE" 