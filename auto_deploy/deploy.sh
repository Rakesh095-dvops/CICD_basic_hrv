#!/bin/bash

# Variables
REPO_URL="https://github.com/Rakesh095-dvops/sample_html_proj.git"
DEST_DIR="/var/www/proj"
BRANCH="main"
LOG_FILE="/var/log/deploy.log"
LOCK_FILE="/tmp/deploy.lock"

# Create lock file to prevent concurrent execution
exec 200>$LOCK_FILE
flock -n 200 || { echo "Another instance of the script is running. Exiting."; exit 1; }
trap "rm -f $LOCK_FILE" EXIT

# Ensure log directory exists
sudo mkdir -p $(dirname $LOG_FILE)
sudo touch $LOG_FILE
sudo chown $(whoami):$(whoami) $LOG_FILE

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "===== Deployment Script Started ====="

# Ensure destination directory exists
if [ ! -d "$DEST_DIR" ]; then
  log "Destination directory does not exist. Creating it..."
  sudo mkdir -p "$DEST_DIR" || { log "Error: Failed to create destination directory."; exit 1; }
  sudo chown -R $(whoami):$(whoami) "$DEST_DIR"  # Grant ownership to the current user
fi

# Ensure destination is a Git repository
if [ ! -d "$DEST_DIR/.git" ]; then
  log "Destination not initialized. Cloning repository..."
  git clone -b $BRANCH $REPO_URL "$DEST_DIR" || { log "Error: Failed to clone repository."; exit 1; }
fi

# Change directory without sudo (use absolute paths for Git commands)
cd "$DEST_DIR" || { log "Error: Failed to change directory to $DEST_DIR."; exit 1; }

# Ensure the directory is a valid Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  log "Error: Destination is not a valid Git repository. Re-cloning..."
  sudo rm -rf "$DEST_DIR"
  git clone -b $BRANCH $REPO_URL "$DEST_DIR" || { log "Error: Failed to clone repository."; exit 1; }
  cd "$DEST_DIR" || { log "Error: Failed to change directory to $DEST_DIR."; exit 1; }
fi

# Fetch latest remote commits
git fetch origin $BRANCH || { log "Error: Failed to fetch remote branch."; exit 1; }

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  log "Error: Uncommitted changes detected. Please commit or stash changes before deploying."
  exit 1
fi

# Pull latest changes
log "Pulling latest changes..."
if ! git pull origin $BRANCH; then
  log "Error: Failed to pull changes. Attempting to reset..."
  git reset --hard origin/$BRANCH || { log "Error: Failed to reset repository."; exit 1; }
fi

# Reload Nginx to pick up any changes
if systemctl is-active --quiet nginx; then
    log "Reloading Nginx..."
    sudo systemctl reload nginx
else
    log "Warning: Nginx is not running. Skipping reload."
fi

log "===== Deployment Script Ended ====="