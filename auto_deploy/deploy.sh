#!/bin/bash
set -e

# === Load environment variables ===
source /opt/auto_deploy/.env

# === Configuration ===
GIT_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
BRANCH="${GITHUB_BRANCH:-main}"
DEPLOY_DIR="/var/www/html"
TEMP_DIR="/tmp/deploy_temp"
LOG_FILE="/opt/auto_deploy/logs/deploy.log"

# === Logging setup ===
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Starting deployment..."

# === Clean temp dir ===
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# === Clone fresh copy ===
echo "Cloning repo..."
git clone --branch "$BRANCH" "$GIT_URL" "$TEMP_DIR"

# === Build/Install if needed ===
if [ -f "$TEMP_DIR/requirements.txt" ]; then
  echo "Installing Python dependencies..."
  pip3 install -r "$TEMP_DIR/requirements.txt"
fi

# === Check for changes ===
if [ -f "$DEPLOY_DIR/.commit_sha" ]; then
  OLD_SHA=$(cat "$DEPLOY_DIR/.commit_sha")
else
  OLD_SHA=""
fi

NEW_SHA=$(cd "$TEMP_DIR" && git rev-parse HEAD)

if [ "$OLD_SHA" == "$NEW_SHA" ]; then
  echo "No new changes to deploy (SHA $NEW_SHA). Exiting."
  exit 0
fi

# === Zero Downtime Deploy ===
echo "Deploying new version..."

# Backup current version
BACKUP_DIR="/opt/auto_deploy/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$DEPLOY_DIR"/* "$BACKUP_DIR" || true

# Sync new version
rsync -a --delete "$TEMP_DIR"/ "$DEPLOY_DIR"/

# Save commit SHA
echo "$NEW_SHA" > "$DEPLOY_DIR/.commit_sha"

# Reload Nginx
echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "[$(date)] Deployment complete for commit $NEW_SHA"
