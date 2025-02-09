#!/bin/bash

# script to make git releases

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: Not on main branch"
    exit 1
fi

# Check if repo is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Repository has uncommitted changes"
    exit 1
fi

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
echo "Current version: $CURRENT_VERSION"

# Split version into parts
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version will be: $NEW_VERSION"

# Update version in pubspec.yaml
sed -i "s/version: .*/version: $NEW_VERSION/" pubspec.yaml

# Build APK
echo "Building APK..."
flutter build apk --release

# Create git tag
git add pubspec.yaml
git commit -m "Release version $NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

# Create release directory if it doesn't exist
mkdir -p releases

# Copy APK to releases directory
cp build/app/outputs/flutter-apk/app-release.apk "releases/structwafels-toolbox-$NEW_VERSION.apk"

# Push changes and tags
echo "Pushing changes to remote..."
git push origin main
git push origin "v$NEW_VERSION"

echo "Release $NEW_VERSION created and pushed successfully!"