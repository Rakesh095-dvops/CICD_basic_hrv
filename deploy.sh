
#!/bin/bash

# Variables
REPO_URL="git@github.com:Rakesh095-dvops/sample_html_proj.git"
DEST_DIR="/var/www/proj"
BRANCH="main"
TMP_DIR="/var/www/proj-temp"
LOG_FILE="/var/log/deploy.log"

# Create log file if it doesn't exist
sudo touch $LOG_FILE
sudo chown $USER:$USER $LOG_FILE

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "===== Deployment Script Started ====="

# Ensure destination exists
if [ ! -d "$DEST_DIR/.git" ]; then
  log "Destination directory has no .git, Cloning repository ..."
  git clone -b $BRANCH $REPO_URL $DEST_DIR
fi

cd $DEST_DIR

# Fetch latest remote commits
git fetch origin $BRANCH

# Get latest local and remote commit SHAs
LOCAL_COMMIT_SHA=$(git rev-parse HEAD)
REMOTE_COMMIT_SHA=$(git rev-parse origin/$BRANCH)

log "Local commit SHA: $LOCAL_COMMIT_SHA"
log "Remote commit SHA: $REMOTE_COMMIT_SHA"

# Compare commit SHAs
if [ "$LOCAL_COMMIT_SHA" == "$REMOTE_COMMIT_SHA" ]; then
  log "No new commits. Skipping deployment."
else
  log "New commit detected. Preparing deployment..."

  # Clean temp directory if it exists
  if [ -d "$TMP_DIR" ]; then
    log "Cleaning old temporary directory..."
    rm -rf $TMP_DIR
  fi

  # Clone latest code into temp directory
  log "Cloning latest code into temp directory..."
  git clone -b $BRANCH $REPO_URL $TMP_DIR

  if [ $? -ne 0 ]; then
    log "ERROR: Failed to clone repository. Aborting deployment."
    exit 1
  fi

  # Test nginx config before swapping
  log "Testing Nginx configuration..."
  sudo nginx -t
  if [ $? -ne 0 ]; then
    log "ERROR: Nginx config test failed! Deployment aborted."
    rm -rf $TMP_DIR
    exit 1
  fi

  # Backup current deployment
  log "Backing up current live site..."
  sudo mv $DEST_DIR "${DEST_DIR}-backup-$(date '+%Y%m%d%H%M%S')"

  # Move temp to live
  log "Deploying new version..."
  sudo mv $TMP_DIR $DEST_DIR

  # Reload Nginx to pick up changes
  log "Reloading Nginx..."
  sudo systemctl reload nginx

  log "Deployment completed successfully."
fi

log "===== Deployment Script Ended ====="
