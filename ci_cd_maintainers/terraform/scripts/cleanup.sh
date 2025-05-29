#!/bin/bash
# Cleanup script for removing old script files after refactoring

set -e

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}Cleaning up old script files after refactoring...${NC}"

# List of files to remove
FILES_TO_REMOVE=(
  "manage_webhooks.sh"
  "test/test_script.sh"
  "test/test_repos.txt"
  "test/README.md"
  "batch_*/repositories.txt"
  "repositories.txt"
)

# Check for and remove each file
for FILE in "${FILES_TO_REMOVE[@]}"; do
  # Use find to handle glob patterns
  MATCHING_FILES=$(find "$SCRIPT_DIR" -name "$FILE" 2>/dev/null || true)
  
  if [ -n "$MATCHING_FILES" ]; then
    echo -e "${YELLOW}Found old file(s) to remove:${NC}"
    echo "$MATCHING_FILES"
    
    read -p "Remove these files? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Remove each matching file
      echo "$MATCHING_FILES" | while read -r f; do
        if [ -f "$f" ]; then
          rm "$f"
          echo -e "${GREEN}Removed: $f${NC}"
        elif [ -d "$f" ]; then
          rm -r "$f"
          echo -e "${GREEN}Removed directory: $f${NC}"
        fi
      done
    else
      echo -e "${YELLOW}Skipping removal of these files${NC}"
    fi
  fi
done

# Check for and remove empty test directory
if [ -d "$SCRIPT_DIR/test" ] && [ -z "$(ls -A "$SCRIPT_DIR/test")" ]; then
  echo -e "${YELLOW}Found empty test directory. Remove it? (y/n)${NC}"
  read -p "" -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rmdir "$SCRIPT_DIR/test"
    echo -e "${GREEN}Removed empty test directory${NC}"
  fi
fi

# Check for batch_webhooks module directory
BATCH_DIR="$PARENT_DIR/batch_webhooks"
if [ -d "$BATCH_DIR" ]; then
  echo -e "${YELLOW}Found old batch_webhooks module directory.${NC}"
  echo -e "${YELLOW}This is no longer needed with the new implementation.${NC}"
  echo -e "${YELLOW}Remove it? (y/n)${NC}"
  read -p "" -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$BATCH_DIR"
    echo -e "${GREEN}Removed batch_webhooks directory${NC}"
  fi
fi

echo -e "${GREEN}Cleanup complete!${NC}"
echo -e "${GREEN}The module now uses a simpler approach with for_each and built-in validation.${NC}" 