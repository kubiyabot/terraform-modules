#!/bin/bash
# Test script for manage_webhooks.sh

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_FILE="$SCRIPT_DIR/test_repos.txt"
TEST_WEBHOOK_URL="https://example.com/webhook"
TEST_EVENTS="check_run,workflow_run"

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== GitHub Webhook Script Test =====${NC}"
echo -e "${BLUE}This script will test the webhook management script with the following parameters:${NC}"
echo -e "  Repository File: ${YELLOW}$REPO_FILE${NC}"
echo -e "  Webhook URL: ${YELLOW}$TEST_WEBHOOK_URL${NC}"
echo -e "  Events: ${YELLOW}$TEST_EVENTS${NC}"
echo

# Check if GitHub token is provided
if [ -z "$1" ]; then
  echo -e "${RED}ERROR: GitHub token required${NC}"
  echo -e "Usage: $0 <github_token> [action]"
  echo -e "   - action: Optional. Either 'create' or 'delete'. Default is 'validate' (validation only)"
  exit 1
fi

GITHUB_TOKEN="$1"
ACTION="${2:-validate}"

# Verify the GitHub token looks reasonable
if [[ ! "$GITHUB_TOKEN" =~ ^gh[ps]_[a-zA-Z0-9]{36,255}$ ]]; then
  echo -e "${YELLOW}WARNING: The GitHub token doesn't match the expected format for a personal access token.${NC}"
  echo -e "${YELLOW}Expected format: ghp_XXXXX... or ghs_XXXXX...${NC}"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Test aborted.${NC}"
    exit 1
  fi
fi

echo -e "${BLUE}Checking GitHub token validity...${NC}"
USER_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/user")

if echo "$USER_RESPONSE" | grep -q "Bad credentials"; then
  echo -e "${RED}ERROR: Invalid GitHub token. Authentication failed.${NC}"
  exit 1
fi

USERNAME=$(echo "$USER_RESPONSE" | jq -r '.login')
if [ "$USERNAME" == "null" ] || [ -z "$USERNAME" ]; then
  echo -e "${RED}ERROR: Unable to retrieve user information. Token may be invalid.${NC}"
  exit 1
fi

echo -e "${GREEN}Token validated successfully for user: $USERNAME${NC}"

# Custom validation-only mode
if [[ "$ACTION" == "validate" ]]; then
  echo -e "${BLUE}Running validation only (no webhooks will be created or deleted)...${NC}"
  
  # Call the script with a special action parameter that will trigger only validation
  TEMP_SCRIPT="$SCRIPT_DIR/temp_validation.sh"
  
  cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
source "$1"
GITHUB_TOKEN="$2"
WEBHOOK_URL="$3"
EVENTS="$4"
REPOS_FILE="$5"

# Create a temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/webhook_operations.log"
VALIDATION_LOG="$TEMP_DIR/validation.log"

echo "Starting validation at $(date)" > "$LOG_FILE"

# Run validation only
check_requirements && validate_token_and_repos
RESULT=$?

# Display logs
cat "$VALIDATION_LOG"
echo
echo "===== Validation Complete ====="
if [[ $RESULT -eq 0 ]]; then
  echo "✅ Validation passed. The token has appropriate access to the repositories."
else
  echo "❌ Validation failed. See above for details."
fi

# Cleanup
rm -rf "$TEMP_DIR"
exit $RESULT
EOF

  chmod +x "$TEMP_SCRIPT"
  "$TEMP_SCRIPT" "$PARENT_DIR/manage_webhooks.sh" "$GITHUB_TOKEN" "$TEST_WEBHOOK_URL" "$TEST_EVENTS" "$REPO_FILE"
  RESULT=$?
  rm "$TEMP_SCRIPT"
  
  if [[ $RESULT -eq 0 ]]; then
    echo -e "${GREEN}✅ Validation successful!${NC}"
  else
    echo -e "${RED}❌ Validation failed!${NC}"
  fi
  
  exit $RESULT
fi

# For create/delete operations
if [[ "$ACTION" != "create" && "$ACTION" != "delete" ]]; then
  echo -e "${RED}ERROR: Invalid action: $ACTION. Use 'create', 'delete', or don't provide for validation only.${NC}"
  exit 1
fi

echo -e "${BLUE}Running webhook script with action: ${YELLOW}$ACTION${NC}"
echo -e "${RED}WARNING: This will ${ACTION} webhooks on your repositories!${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Test aborted.${NC}"
  exit 1
fi

# Run the actual script
"$PARENT_DIR/manage_webhooks.sh" "$GITHUB_TOKEN" "$TEST_WEBHOOK_URL" "$TEST_EVENTS" "$REPO_FILE" "$ACTION" 