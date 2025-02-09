#!/bin/bash

# script to make git releases

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: Not on main branch"
    exit 1
fi

# # Check if repo is clean
# if [ -n "$(git status --porcelain)" ]; then
#     echo "Error: Repository has uncommitted changes"
#     exit 1
# fi

CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo "Current version: $CURRENT_VERSION"

# Split version into parts
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version will be: $NEW_VERSION"