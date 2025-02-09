#!/bin/bash

# script to make git releases

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

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

# Create git tag and commit
git add pubspec.yaml
git commit -m "Release version $NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

# Push changes and tags
echo "Pushing changes to remote..."
git push origin main
git push origin "v$NEW_VERSION"

# Create GitHub release with APK
echo "Creating GitHub release..."
gh release create "v$NEW_VERSION" \
    --title "Release v$NEW_VERSION" \
    --notes "Release version $NEW_VERSION" \
    build/app/outputs/flutter-apk/app-release.apk#"structwafels-toolbox-$NEW_VERSION.apk"

echo "Release $NEW_VERSION created and pushed successfully!"