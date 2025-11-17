#!/bin/bash

# Usage: ./update_repos_recursive.sh <branch_name> <root_path>

BRANCH="$1"
ROOT_DIR="$2"

if [ -z "$BRANCH" ] || [ -z "$ROOT_DIR" ]; then
  echo "Usage: $0 <branch_name> <root_path>"
  exit 1
fi

if [ ! -d "$ROOT_DIR" ]; then
  echo "Directory $ROOT_DIR does not exist."
  exit 1
fi

REPOS=$(find "$ROOT_DIR" -type d -name ".git" | sed 's/\/.git$//')

if [ -z "$REPOS" ]; then
  echo "No git repositories found under $ROOT_DIR"
  exit 0
fi

for repo in $REPOS; do
  echo "==== Updating $repo ===="
  cd "$repo" || { echo "Cannot cd into $repo"; continue; }

  if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes detected in $repo, skipping..."
    cd - >/dev/null
    continue
  fi

  git fetch origin "$BRANCH"

  if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Local branch $BRANCH does not exist, creating it to track origin/$BRANCH..."
    git branch --track "$BRANCH" "origin/$BRANCH"
  fi

  git checkout "$BRANCH"

  LOCAL_HEAD=$(git rev-parse "$BRANCH")
  REMOTE_HEAD=$(git rev-parse "origin/$BRANCH")

  if [ "$LOCAL_HEAD" = "$REMOTE_HEAD" ]; then
    echo "Already up-to-date."
  else
    #fast-forward possible ?
    if git merge-base --is-ancestor "$LOCAL_HEAD" "$REMOTE_HEAD"; then
      git merge --ff-only "origin/$BRANCH"
      echo "Fast-forwarded $BRANCH to origin/$BRANCH."
    else
      echo "Cannot fast-forward $BRANCH (diverged). Skipping..."
    fi
  fi

  cd - >/dev/null
done

echo "All repositories processed."

