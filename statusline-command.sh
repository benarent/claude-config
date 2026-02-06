#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Get just the directory name (like %c in zsh)
dir_name=$(basename "$current_dir")

# Get git branch if in a git repo (with --no-optional-locks to avoid lock issues)
git_branch=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$current_dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    
    # Check if repo is dirty
    if git -C "$current_dir" --no-optional-locks diff --quiet 2>/dev/null && git -C "$current_dir" --no-optional-locks diff --cached --quiet 2>/dev/null; then
        # Clean repo
        git_branch=$(printf " \033[1;34mgit:(\033[0;31m%s\033[1;34m)" "$branch")
    else
        # Dirty repo
        git_branch=$(printf " \033[1;34mgit:(\033[0;31m%s\033[1;34m) \033[0;33m✗" "$branch")
    fi
fi

# Show green arrow (robbyrussell style)
printf "\033[1;32m➜ \033[0;36m%s\033[0m%s " "$dir_name" "$git_branch"
