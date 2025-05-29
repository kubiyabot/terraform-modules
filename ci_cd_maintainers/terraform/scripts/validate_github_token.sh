#!/bin/bash
# GitHub Token Validation Script
# This script validates that a GitHub token has the necessary access to repositories
# Usage: ./validate_github_token.sh <GITHUB_TOKEN> <COMMA_SEPARATED_REPOS>

set -e

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}GitHub Token & Repository Validator${NC}"
echo "---------------------------------------"

# Check parameters
if [ -z "$1" ]; then
  echo -e "${RED}Error: GitHub token required${NC}"
  echo "Usage: $0 <github_token> [repositories]"
  echo "  - github_token: Your GitHub personal access token"
  echo "  - repositories: Optional comma-separated list of repositories (e.g., 'org/repo1,org/repo2')"
  exit 1
fi

GITHUB_TOKEN="$1"
REPOS="$2"

# Validate token format
if [[ ! "$GITHUB_TOKEN" =~ ^gh[ps]_[a-zA-Z0-9]{36,255}$ ]]; then
  echo -e "${YELLOW}Warning: GitHub token doesn't match expected format for a personal access token${NC}"
  echo -e "${YELLOW}Expected format: ghp_XXXXX... or ghs_XXXXX...${NC}"
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Validation aborted${NC}"
    exit 1
  fi
fi

# Validate the token by fetching user info
echo -e "${BLUE}Checking GitHub token...${NC}"
USER_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/user")

if echo "$USER_RESPONSE" | grep -q "Bad credentials"; then
  echo -e "${RED}Error: Invalid GitHub token. Authentication failed.${NC}"
  exit 1
fi

USERNAME=$(echo "$USER_RESPONSE" | grep -o '"login": *"[^"]*"' | cut -d'"' -f4)
if [ -z "$USERNAME" ]; then
  echo -e "${RED}Error: Could not retrieve username. Token may be invalid.${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Token validated. Authenticated as: $USERNAME${NC}"

# If no repositories specified, check token scopes
if [ -z "$REPOS" ]; then
  echo -e "${BLUE}No repositories specified. Checking token scopes...${NC}"
  
  # Get token scopes from GitHub API
  SCOPES=$(curl -s -I -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" | grep -i "X-OAuth-Scopes:" | cut -d: -f2- | tr -d ' ')
  
  echo -e "${BLUE}Token scopes: $SCOPES${NC}"
  
  # Check for necessary scopes
  if [[ "$SCOPES" == *"repo"* ]]; then
    echo -e "${GREEN}✓ Token has 'repo' scope - can access private repositories${NC}"
  elif [[ "$SCOPES" == *"public_repo"* ]]; then
    echo -e "${YELLOW}⚠️ Token has 'public_repo' scope only - can only access public repositories${NC}"
  else
    echo -e "${RED}✗ Token doesn't have 'repo' or 'public_repo' scope - may have limited repository access${NC}"
    echo -e "${RED}Please update token permissions at: https://github.com/settings/tokens${NC}"
  fi
  
  if [[ "$SCOPES" == *"admin:org_hook"* || "$SCOPES" == *"admin:org"* ]]; then
    echo -e "${GREEN}✓ Token has admin organization hook permissions${NC}"
  else
    echo -e "${YELLOW}⚠️ Token doesn't have 'admin:org_hook' scope - may not be able to manage organization webhooks${NC}"
  fi
  
  echo -e "${GREEN}Token validation complete. Use this token in your Terraform configuration.${NC}"
  exit 0
fi

# Validate access to each repository
echo -e "${BLUE}Validating access to repositories...${NC}"
IFS=',' read -ra REPO_ARRAY <<< "$REPOS"
SUCCESS=true

for REPO in "${REPO_ARRAY[@]}"; do
  REPO=$(echo "$REPO" | xargs) # Trim whitespace
  echo -n "Checking $REPO... "
  
  # Try to access repository
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO")
  
  if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Accessible${NC}"
    
    # Check if we have admin access (needed for webhook creation)
    PERMISSIONS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$REPO" | grep -o '"permissions": {[^}]*}')
    
    if echo "$PERMISSIONS" | grep -q '"admin": true'; then
      echo -e "  ${GREEN}✓ Admin access - can create webhooks${NC}"
    else
      echo -e "  ${RED}✗ No admin access - cannot create webhooks${NC}"
      SUCCESS=false
    fi
  else
    echo -e "${RED}✗ Not accessible (HTTP $RESPONSE)${NC}"
    SUCCESS=false
  fi
done

echo "---------------------------------------"
if [ "$SUCCESS" = true ]; then
  echo -e "${GREEN}All repositories validated successfully!${NC}"
  echo -e "${GREEN}You can proceed with Terraform deployment.${NC}"
  exit 0
else
  echo -e "${RED}Some repositories could not be accessed or lack admin permissions.${NC}"
  echo -e "${RED}Please check your token permissions and repository access.${NC}"
  exit 1
fi 