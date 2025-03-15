#!/bin/bash

# Usage instruction if no remote URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <remote-url> [commit-message]"
  exit 1
fi

REMOTE_URL=$1
COMMIT_MSG=${2:-"init"}  

if [ ! -d .git ]; then
  echo "Initializing new Git repository..."
  git init
fi

echo "Adding files..."
git add .

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Creating initial commit with message: '$COMMIT_MSG'"
  git commit -m "$COMMIT_MSG"
else
  echo "Committing changes with message: '$COMMIT_MSG'"
  git commit -m "$COMMIT_MSG"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "Remote origin already exists: $(git remote get-url origin)"
else
  echo "Adding remote origin: $REMOTE_URL"
  git remote add origin "$REMOTE_URL"
fi

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Renaming branch $CURRENT_BRANCH to main..."
  git branch -M main
fi

echo "Pushing to remote repository..."
git push -u origin main

